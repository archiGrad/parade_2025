import asyncio
import websockets
import json
import uuid
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Store connected clients
connected_clients = {}  # Change to dictionary to map client websocket to player_id

# Game state to synchronize
game_state = {
    "players": {},
    "messages": [],
    "imageScores": {},
    "blocks": []  # Add this to track blocks

}

async def handle_client(websocket, path=None):
    # Generate unique player ID
    player_id = str(uuid.uuid4())
    
    try:
        # Register client with its ID
        connected_clients[websocket] = player_id
        logging.info(f"New client connected: {player_id}")
        
        # Send initial game state and player ID
        await websocket.send(json.dumps({
            'type': 'initialize',
            'player_id': player_id,
            'existing_messages': game_state['messages'],
            'imageScores': game_state['imageScores'],  # Send current image scores to new clients
            'blocks': game_state['blocks']

        }))
        
        # Add player to game state
        game_state['players'][player_id] = {
            'id': player_id,
            'connected': True
        }
        
        async for message in websocket:
            try:
                # Parse incoming data
                data = json.loads(message)
                
                # Handle different types of messages
                if data.get('type') == 'player_update':
                    # Existing player update logic
                    player_data = data.get('player', {})
                    player_data['id'] = player_id
                    game_state['players'][player_id] = player_data
                    
                    # Broadcast to other clients
                    for client, client_id in connected_clients.items():
                        if client != websocket:
                            await client.send(json.dumps({
                                'type': 'player_update',
                                'player': player_data
                            }))
                elif data.get('type') == 'player_trail':
                    # Broadcast trail to other clients
                    for client, client_id in connected_clients.items():
                        if client != websocket:
                            await client.send(json.dumps({
                                'type': 'player_trail',
                                'trail': data.get('trail')
                            }))            
               


            
                
                elif data.get('type') == 'place_block':
                    block_data = data.get('block', {})

                    game_state['blocks'].append(block_data)
                    logging.info(f"Stored new block, total blocks: {len(game_state['blocks'])}")

                    
                    for client, client_id in connected_clients.items():
                        if client != websocket:
                            await client.send(json.dumps({
                                'type': 'place_block',
                                'block': block_data
                            }))
                
                
                 


                elif data.get('type') == 'place_icon':
                    icon_data = data.get('icon', {})
                    icon_data['id'] = player_id  
                    
                    # Extract message if present
                    message_data = data.get('message', None)
                    
                    # Store message in game state (limit to last 10)
                    if message_data:
                        game_state['messages'].insert(0, message_data)
                        if len(game_state['messages']) > 10:
                            game_state['messages'] = game_state['messages'][:10]
                    
                    for client, client_id in connected_clients.items():
                        if client != websocket:
                            await client.send(json.dumps({
                                'type': 'place_icon',
                                'icon': icon_data
                            }))
			    
                            if message_data:
                               await client.send(json.dumps({
                                   'type': 'message',
                                   'message': message_data
                               }))
                


                elif data.get('type') == 'image_score_update':
		    # Get score data
                    image_score = data.get('imageScore', {})
                    image_id = image_score.get('id')
                    score = image_score.get('score')	
                    if image_id is not None and score is not None:
                        game_state['imageScores'][image_id] = score
		    
                        for client, client_id in connected_clients.items():
                            if client != websocket:
                                await client.send(json.dumps({
                                    'type': 'image_score_update',
                                    'imageScore': {
                                        'id': image_id,
                                        'score': score
                                         }
                                     }))


                
                elif data.get('type') == 'player_texture_update':
                    # Handle texture update
                    player_data = data.get('player', {})
                    player_data['id'] = player_id
                    
                    # Broadcast to other clients
                    for client, client_id in connected_clients.items():
                        if client != websocket:
                            await client.send(json.dumps({
                                'type': 'player_texture_update',
                                'player': player_data
                            }))
                
                elif data.get('type') == 'score_update':
                    # Handle score update
                    score_data = data.get('score', {})
                    score_data['id'] = player_id  # Ensure correct player ID
                    
                    # Store scores in game state for new players
                    if 'scores' not in game_state:
                        game_state['scores'] = {}
                    
                    game_state['scores'][player_id] = score_data.get('score', 0)
                    
                    # Broadcast to other clients
                    for client, client_id in connected_clients.items():
                        if client != websocket:  # Send to all clients except sender
                            await client.send(json.dumps({
                                'type': 'score_update',
                                'score': score_data
                            }))    
            except websockets.exceptions.ConnectionClosed as e:
               logging.info(f"Client {player_id} disconnected. Code: {e.code}, Reason: {e.reason}")
    
    except Exception as e:
        logging.error(f"Unexpected error with client {player_id}: {str(e)}")
    
    finally:
        # Clean up after disconnection
        if websocket in connected_clients:
            player_id = connected_clients[websocket]
            del connected_clients[websocket]
            logging.info(f"Removed client {player_id} from connected_clients")
        
        # Remove player from game state
        if player_id in game_state['players']:
            del game_state['players'][player_id]
            logging.info(f"Removed player {player_id} from game state")
        
        # Broadcast disconnection to all remaining clients
        disconnect_msg = json.dumps({
            'type': 'player_disconnect',
            'id': player_id
        })
        
        broadcast_tasks = []
        for client, _ in connected_clients.items():
            try:
                broadcast_tasks.append(client.send(disconnect_msg))
            except Exception as e:
                logging.error(f"Error preparing disconnect broadcast: {e}")
        
        if broadcast_tasks:
            # Wait for all broadcast messages to be sent
            await asyncio.gather(*broadcast_tasks, return_exceptions=True)
            logging.info(f"Broadcast disconnect notification for player {player_id} to {len(broadcast_tasks)} clients")
        
        logging.info(f"Cleanup complete for player {player_id}, {len(connected_clients)} clients remain")

async def main():
    # Start WebSocket server
    server = await websockets.serve(handle_client, "0.0.0.0", 8765)
    logging.info("WebSocket server started on ws://0.0.0.0:8765")
    await server.wait_closed()

if __name__ == "__main__":
    asyncio.run(main())
