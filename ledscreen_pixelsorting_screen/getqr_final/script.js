window.onload = function() {
	runSketch();
};

function runSketch() {
	var renderer, renderTarget1, renderTarget2, sceneShader, sceneScreen, camera, clock, uniforms, materialScreen, imgTexture;

// Create Stats.js instance
	var stats = new Stats();
	stats.showPanel(0); // 0: fps, 1: ms, 2: mb, 3+: custom
	document.body.appendChild(stats.dom);
	
	// Position the stats panel in the top-left corner
	stats.dom.style.position = 'absolute';
	stats.dom.style.left = '0px';
	stats.dom.style.top = '0px';




	init();
	animate();

function setupKeyControls() {
  const possibleValues = [1, 1, 2, 5, 3, 5, 7, 10, 20, 10];
  let currentIndex = 2; // Start with the third value (5) as base value
  
  // Initialize with base value
  uniforms.u_displaceMagnitude.value = possibleValues[currentIndex];
  
  // Set up auto-changing displacement magnitude
  function setupAutoDisplacement() {
    // Random interval between 5 seconds and 1 minute (5000ms - 60000ms)
    function getRandomInterval() {
      return Math.floor(Math.random() * (60000 - 5000 + 1)) + 5000;
    }
    
    function changeDisplacement() {
      // Pick a random value from possibleValues
      let newIndex = Math.floor(Math.random() * possibleValues.length);
      currentIndex = newIndex;
      
      console.log("Auto changing displacement to:", possibleValues[currentIndex]);
      uniforms.u_displaceMagnitude.value = possibleValues[currentIndex];
      
      // Schedule next change with a new random interval
      setTimeout(changeDisplacement, getRandomInterval());
    }
    
    // Start the cycle
    setTimeout(changeDisplacement, getRandomInterval());
  }
  
  // Call the auto-displacement function to start the process
  setupAutoDisplacement();
  
  // Still keep manual controls for testing
  document.addEventListener('keydown', function(event) {
    if (event.key === 'j') {
      // Move to next value in array
      currentIndex = (currentIndex + 1) % possibleValues.length;
      uniforms.u_displaceMagnitude.value = possibleValues[currentIndex];
    } else if (event.key === 'e') {
      // Generate QR code
      captureAndGenerateQR();
    } else if (event.key === 'r') {
      // Load random texture
      uniforms.u_texture.value = null;
      loadTexture(getRandomImageName());
      materialScreen.map = imgTexture;
      materialScreen.needsUpdate = true;
    }
  });
}
		function setupAutoImageChange() {
		  // Change image every 30 seconds (30000ms)
		  const changeInterval = 60000; 
		  
		  console.log("Setting up auto image change with interval:", changeInterval);
		  
		  setInterval(() => {
		    console.log("Auto changing image...");
		    
		    // Create a new loader and load a different image
		    var loader = new THREE.TextureLoader();
		    var newImagePath = getRandomImageName();
		    
		    loader.load(newImagePath, function(texture) {
		      console.log("New image loaded:", newImagePath);
		      
		      // Properly reset everything
		      texture.minFilter = THREE.LinearFilter;
		      texture.magFilter = THREE.LinearFilter;
		      
		      // Important: Reset the rendering pipeline
		      uniforms.u_texture.value = null;
		      
		      // Replace the texture
		      imgTexture = texture;
		      
		      // Instead of immediately using it, we'll use it on the next render cycle
		      // This is important to avoid the source/destination texture conflict
		      setTimeout(() => {
			// Reset material to the original image first
			materialScreen.map = imgTexture;
			materialScreen.needsUpdate = true;
			
			// Reset the render targets to avoid conflicts
			uniforms.u_texture.value = null;
			
			console.log("Texture updated successfully");
		      }, 100);
		    });
		  }, changeInterval);
		}
	function init() {
		// Initialize the WebGL renderer
		renderer = new THREE.WebGLRenderer({
			preserveDrawingBuffer: true
		});
		renderer.setPixelRatio(window.devicePixelRatio);
		renderer.setSize(window.innerWidth, window.innerHeight);
		renderer.setClearColor(new THREE.Color(0, 0, 0));

		// Add the renderer to the sketch container
		var container = document.getElementById("sketch-container");
		container.appendChild(renderer.domElement);

		// Initialize the render targets
		var size = renderer.getDrawingBufferSize();
		var options = {
			minFilter: THREE.NearestFilter,
			magFilter: THREE.NearestFilter,
			format: THREE.RGBAFormat
		};
		renderTarget1 = new THREE.WebGLRenderTarget(size.width, size.height, options);
		renderTarget2 = new THREE.WebGLRenderTarget(size.width, size.height, options);

		// Initialize the scenes
		sceneShader = new THREE.Scene();
		sceneScreen = new THREE.Scene();

		// Initialize the camera
		camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);

		// Initialize the clock
		clock = new THREE.Clock(true);

		// Create the plane geometry
		var geometry = new THREE.PlaneBufferGeometry(2, 2);

		// Define the shader uniforms
		uniforms = {
			u_time: {
				type: "f",
				value: 0.0
			},
			u_frame: {
				type: "f",
				value: 0.0
			},
			u_resolution: {
				type: "v2",
				value: new THREE.Vector2(window.innerWidth, window.innerHeight)
						.multiplyScalar(window.devicePixelRatio)
			},
			u_mouse: {
				type: "v2",
				value: new THREE.Vector2(0.7 * window.innerWidth, window.innerHeight)
						.multiplyScalar(window.devicePixelRatio)
			},
			u_texture: {
				type: "t",
				value: null
			},
			u_displaceMagnitude: {
				type: "f",
				value: 5.0
			}
		};

		// Create the shader material
		var materialShader = new THREE.ShaderMaterial({
			uniforms: uniforms,
			vertexShader: document.getElementById("vertexShader").textContent,
			fragmentShader: document.getElementById("fragmentShader").textContent
		});

		// Create the screen material
		materialScreen = new THREE.MeshBasicMaterial();

		// Create the meshes and add them to the scenes
		var meshShader = new THREE.Mesh(geometry, materialShader);
		var meshScreen = new THREE.Mesh(geometry, materialScreen);
		sceneShader.add(meshShader);
		sceneScreen.add(meshScreen);

		// Load the image texture
		loadTexture(getRandomImageName());

		// Setup controls and auto image change
		setupKeyControls();
		setupAutoImageChange();

		// Add event listeners for window resize and mouse/touch movement
		window.addEventListener('resize', onWindowResize, false);
		document.addEventListener('mousemove', onMouseMove, false);
		document.addEventListener('touchmove', onTouchMove, false);
	}

	function addQRCodeButton() {
		// Create QR button
		var qrButton = document.createElement('button');
		qrButton.innerText = 'QR';
		qrButton.style.position = 'absolute';
		qrButton.style.top = '10px';
		qrButton.style.right = '100px';
		qrButton.style.zIndex = '100';
		qrButton.style.cursor = 'pointer';
		
		// Create QR container
		var qrContainer = document.createElement('div');
		qrContainer.id = 'qrCodeContainer';
		
		// Create content div
		var qrContent = document.createElement('div');
		qrContent.id = 'qrContent';
		qrContent.style.color = 'white';
		
		// Add elements to DOM
		qrContainer.appendChild(qrContent);
		document.body.appendChild(qrButton);
		document.body.appendChild(qrContainer);
		
		// Add event listeners
		qrButton.addEventListener('click', captureAndGenerateQR);
	}
	
	function captureAndGenerateQR() {
		var qrContainer = document.getElementById('qrCodeContainer');
		var qrContent = document.getElementById('qrContent');
		
		qrContainer.style.display = 'block';
		qrContent.innerHTML = 'generating qr..';
		
		// Clear any existing timeout and interval
		if (window.qrHideTimeout) {
			clearTimeout(window.qrHideTimeout);
		}
		if (window.countdownInterval) {
			clearInterval(window.countdownInterval);
		}
		
		// Set timeout to hide QR code after 10 seconds
		window.qrHideTimeout = setTimeout(function() {
			qrContainer.style.display = 'none';
		}, 10000);
		
		// Create countdown element
		var countdownDiv = document.createElement('div');
		countdownDiv.id = 'countdown';
		countdownDiv.style.marginTop = '10px';
		countdownDiv.style.color = 'white';
		countdownDiv.style.fontFamily = 'Arial';
		
		try {
			// Force a render
			render();
			
			// Create a temporary canvas
			var tempCanvas = document.createElement('canvas');
			var maxDimension = 1000;
			
			// Calculate new dimensions
			var width = renderer.domElement.width;
			var height = renderer.domElement.height;
			var ratio = Math.min(maxDimension / width, maxDimension / height);
			
			tempCanvas.width = Math.floor(width * ratio);
			tempCanvas.height = Math.floor(height * ratio);
			
			var tempContext = tempCanvas.getContext('2d');
			tempContext.drawImage(renderer.domElement, 0, 0, tempCanvas.width, tempCanvas.height);
			
			// Get image data
			var imageData = tempCanvas.toDataURL('image/jpeg', 0.5);
			
			// Send to server
			var formData = new FormData();
			formData.append('image_data', imageData);
			
			fetch('/generate-qr', {
				method: 'POST',
				body: formData
			})
			.then(response => response.json())
			.then(data => {
				if (!data.success) {
					throw new Error(data.error || 'Failed to generate QR code');
				}
				
				// Display QR code
				qrContent.innerHTML = `
					<img src="${data.qr_code}?t=${Date.now()}" alt="QR Code" style="max-width:300px; max-height:300px;" />
				`;
				
				// Add countdown after QR code
				qrContent.appendChild(countdownDiv);
				
				// Start countdown
				var secondsLeft = 7;
				countdownDiv.textContent = `${secondsLeft}s`;
				
				window.countdownInterval = setInterval(function() {
					secondsLeft--;
					countdownDiv.textContent = `${secondsLeft}s`;
					
					if (secondsLeft <= 0) {
						clearInterval(window.countdownInterval);
					}
				}, 1000);
			})
			.catch(error => {
				qrContent.innerHTML = 'Error: ' + error.message;
				console.error(error);
			});
			
		} catch (error) {
			qrContent.innerHTML = 'Error: ' + error.message;
			console.error(error);
		}
	}






function getRandomImageName() {
  var imageList = [
		"./images/brief",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page1_img1.png",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page2_img4.jpeg",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page2_img8.jpeg",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page4_img1.jpeg",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page5_img11.jpeg",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page5_img12.jpeg",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page5_img18.jpeg",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page5_img1.jpeg",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page5_img23.png",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page5_img24.png",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page5_img2.jpeg",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page5_img5.jpeg",
		"./images/Climatic Ornament workshop report - Naphol [Pound] Chanakul_page5_img7.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page1_img7.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page2_img2.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img10.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img12.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img13.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img1.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img2.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img3.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img4.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img6.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img7.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img8.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page3_img9.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page4_img10.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page4_img11.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page4_img12.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page4_img1.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page4_img2.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page4_img4.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page4_img5.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page4_img6.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page4_img8.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page4_img9.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img10.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img11.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img12.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img1.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img2.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img3.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img4.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img5.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img6.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img7.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img8.jpeg",
		"./images/DecolonizingSymmetry_Chayutpon Jirajaturapak - Chayutpon Jirajaturapak_page5_img9.jpeg",
		"./images/DEX_ToolsOfANewCraft (1).jpeg",
		"./images/DEX_ToolsOfANewCraft (2).jpeg",
		"./images/DEX_ToolsOfANewCraft (3).jpeg",
		"./images/DEX_ToolsOfANewCraft (4).jpeg",
		"./images/DEX_ToolsOfANewCraft (5).jpeg",
		"./images/DEX_ToolsOfANewCraft (6).jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page1_img1.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page2_img1.png",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page2_img2.png",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page2_img4.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page2_img5.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page2_img6.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page3_img5.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page3_img6.png",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page4_img1.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page4_img2.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page4_img3.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page4_img4.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page4_img5.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page4_img6.jpeg",
		"./images/FluidTectonics_AkarawinPreedawiphat - Akarawin Preedawiphat_page5_img2.jpeg",
		"./images/FluidTectonics_PatrLeelarasamee - Patr Leelarasamee_page1_img1.jpeg",
		"./images/FluidTectonics_PatrLeelarasamee - Patr Leelarasamee_page3_img3.jpeg",
		"./images/FluidTectonics_PatrLeelarasamee - Patr Leelarasamee_page3_img5.jpeg",
		"./images/FluidTectonics_PatrLeelarasamee - Patr Leelarasamee_page4_img1.jpeg",
		"./images/FluidTectonics_PatrLeelarasamee - Patr Leelarasamee_page4_img3.jpeg",
		"./images/FluidTectonics_PunnaphatMeesuk - Punnaphat [I-tim] Meesuk_page1_img1.jpeg",
		"./images/FluidTectonics_PunnaphatMeesuk - Punnaphat [I-tim] Meesuk_page2_img1.jpeg",
		"./images/FluidTectonics_PunnaphatMeesuk - Punnaphat [I-tim] Meesuk_page2_img2.jpeg",
		"./images/hybrid58915_page1_img12.png",
		"./images/hybrid58915_page1_img2.png",
		"./images/list.txt",
		"./images/MultiAuthorHybrid_KritAhunai - Krit [Krit] Ahunai_page1_img1.jpeg",
		"./images/MultiAuthorHybrid_KritAhunai - Krit [Krit] Ahunai_page2_img1.jpeg",
		"./images/MultiAuthorHybrid_KritAhunai - Krit [Krit] Ahunai_page2_img5.jpeg",
		"./images/MultiAuthorHybrid_KritAhunai - Krit [Krit] Ahunai_page3_img1.jpeg",
		"./images/MultiAuthorHybrid_KritAhunai - Krit [Krit] Ahunai_page3_img4.jpeg",
		"./images/SensorialHybrids_KullanitSinchai - Kullanit Sinchai_page1_img1.jpeg",
		"./images/SensorialHybrids_KullanitSinchai - Kullanit Sinchai_page2_img3.jpeg",
		"./images/SensorialHybrids_KullanitSinchai - Kullanit Sinchai_page2_img4.jpeg",
		"./images/SensorialHybrids_KullanitSinchai - Kullanit Sinchai_page3_img2.jpeg",
		"./images/StateOfRepair_ChawanyaPridaphatrakun - Chawanya Pridaphatrakun_page2_img1.jpeg",
		"./images/StateOfRepair_ChawanyaPridaphatrakun - Chawanya Pridaphatrakun_page2_img2.jpeg",
		"./images/StateOfRepair_ChawanyaPridaphatrakun - Chawanya Pridaphatrakun_page2_img3.jpeg",
		"./images/StateOfRepair_ChawanyaPridaphatrakun - Chawanya Pridaphatrakun_page2_img4.jpeg",
		"./images/StateOfRepair_ChawanyaPridaphatrakun - Chawanya Pridaphatrakun_page2_img5.jpeg",
		"./images/StateOfRepair_ChawanyaPridaphatrakun - Chawanya Pridaphatrakun_page3_img2.jpeg",
		"./images/StateOfRepair_ChawanyaPridaphatrakun - Chawanya Pridaphatrakun_page3_img3.jpeg",
		"./images/StateOfRepair_ChawanyaPridaphatrakun - Chawanya Pridaphatrakun_page3_img4.jpeg",
		"./images/StateOfRepair_ChomdaoWongthawatchai - Chomdao Wongthawatchai_page1_img1.jpeg",
		"./images/StateOfRepair_ChomdaoWongthawatchai - Chomdao Wongthawatchai_page2_img1.jpeg",
		"./images/StateOfRepair_ChomdaoWongthawatchai - Chomdao Wongthawatchai_page2_img4.jpeg",
		"./images/StateOfRepair_ChomdaoWongthawatchai - Chomdao Wongthawatchai_page2_img6.jpeg",
		"./images/StateOfRepair_ChomdaoWongthawatchai - Chomdao Wongthawatchai_page3_img1.jpeg",
		"./images/StateOfRepair_ChomdaoWongthawatchai - Chomdao Wongthawatchai_page3_img3.jpeg",
		"./images/StateOfRepair_ChomdaoWongthawatchai - Chomdao Wongthawatchai_page3_img4.jpeg",
		"./images/StateofRepair-HybridObjects&3DPrintedSeams_NadaRuengchinda - Nada [Ja] Ruengchinda(1)_page1_img1.jpeg",
		"./images/StateofRepair-HybridObjects&3DPrintedSeams_NadaRuengchinda - Nada [Ja] Ruengchinda(1)_page2_img3.png",
		"./images/StateofRepair-HybridObjects&3DPrintedSeams_NadaRuengchinda - Nada [Ja] Ruengchinda(1)_page2_img6.jpeg",
		"./images/StateofRepair-HybridObjects&3DPrintedSeams_NadaRuengchinda - Nada [Ja] Ruengchinda(1)_page3_img1.jpeg",
		"./images/StateofRepair-HybridObjects&3DPrintedSeams_NadaRuengchinda - Nada [Ja] Ruengchinda(1)_page3_img2.jpeg",
		"./images/StateofRepair-HybridObjects&3DPrintedSeams_NadaRuengchinda - Nada [Ja] Ruengchinda(1)_page3_img4.jpeg",
		"./images/StateofRepair_PawinThanatit - Pawin Thanatit_page1_img1.jpeg",
		"./images/StateofRepair_PawinThanatit - Pawin Thanatit_page2_img1.jpeg",
		"./images/StateofRepair_PawinThanatit - Pawin Thanatit_page2_img2.jpeg",
		"./images/StateofRepair_PawinThanatit - Pawin Thanatit_page2_img4.jpeg",
		"./images/StateofRepair_PawinThanatit - Pawin Thanatit_page2_img5.jpeg",
		"./images/StateofRepair_PawinThanatit - Pawin Thanatit_page2_img6.jpeg",
		"./images/StateofRepair_PawinThanatit - Pawin Thanatit_page3_img1.jpeg",
		"./images/StateofRepair_PawinThanatit - Pawin Thanatit_page3_img3.jpeg",
		"./images/StateofRepair_PichaRiyasan - Picha Riyasan_page1_img1.jpeg",
		"./images/StateofRepair_PichaRiyasan - Picha Riyasan_page2_img1.jpeg",
		"./images/StateofRepair_PichaRiyasan - Picha Riyasan_page2_img2.jpeg",
		"./images/StateofRepair_PichaRiyasan - Picha Riyasan_page2_img3.jpeg",
		"./images/StateofRepair_PichaRiyasan - Picha Riyasan_page2_img4.jpeg",
		"./images/StateofRepair_PichaRiyasan - Picha Riyasan_page2_img5.jpeg",
		"./images/StateofRepair_PichaRiyasan - Picha Riyasan_page3_img1.jpeg",
		"./images/StateofRepair_PichaRiyasan - Picha Riyasan_page3_img4.jpeg",
		"./images/StateofRepair_PichaRiyasan - Picha Riyasan_page3_img5.jpeg",
		"./images/StateofRepair_PichaRiyasan - Picha Riyasan_page3_img8.jpeg",
		"./images/StateofRepair_PloyCatalinaPloysongsang - Ploy Catalina [Ploy] Ploysongsang_page1_img1.jpeg",
		"./images/StateofRepair_PloyCatalinaPloysongsang - Ploy Catalina [Ploy] Ploysongsang_page2_img1.jpeg",
		"./images/StateofRepair_PloyCatalinaPloysongsang - Ploy Catalina [Ploy] Ploysongsang_page2_img2.jpeg",
		"./images/StateofRepair_PloyCatalinaPloysongsang - Ploy Catalina [Ploy] Ploysongsang_page2_img3.jpeg",
		"./images/StateofRepair_PloyCatalinaPloysongsang - Ploy Catalina [Ploy] Ploysongsang_page2_img4.jpeg",
		"./images/StateofRepair_PloyCatalinaPloysongsang - Ploy Catalina [Ploy] Ploysongsang_page2_img5.jpeg",
		"./images/StateofRepair_PloyCatalinaPloysongsang - Ploy Catalina [Ploy] Ploysongsang_page2_img6.jpeg",
		"./images/StateofRepair_PloyCatalinaPloysongsang - Ploy Catalina [Ploy] Ploysongsang_page3_img2.jpeg",
		"./images/StateofRepair_PloyCatalinaPloysongsang - Ploy Catalina [Ploy] Ploysongsang_page3_img4.jpeg",
		"./images/StateOfRepair_PruekHongboontai - Pruek “Chutae” Hongboontai_page1_img1.jpeg",
		"./images/StateOfRepair_PruekHongboontai - Pruek “Chutae” Hongboontai_page2_img2.jpeg",
		"./images/StateOfRepair_PruekHongboontai - Pruek “Chutae” Hongboontai_page2_img6.jpeg",
		"./images/StateOfRepair_PruekHongboontai - Pruek “Chutae” Hongboontai_page3_img1.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page1_img1.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page2_img2.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page2_img3.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page2_img5.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page3_img2.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page3_img5.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page3_img6.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page4_img13.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page4_img2.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page4_img3.jpeg",
		"./images/StateofRepair_SuppasilpCharoenkraikamol - Suppasilp Charoenkraikamol_page4_img7.jpeg",
		"./images/StateOfRepair_TanakornAnongpornyoskul - Tanakorn [Ice] Anongpornyoskul_page2_img3.jpeg",
		"./images/StateOfRepair_TanakornAnongpornyoskul - Tanakorn [Ice] Anongpornyoskul_page2_img4.jpeg",
		"./images/StateOfRepair_TanakornAnongpornyoskul - Tanakorn [Ice] Anongpornyoskul_page2_img5.jpeg",
		"./images/StateOfRepair_TanakornAnongpornyoskul - Tanakorn [Ice] Anongpornyoskul_page2_img6.jpeg",
		"./images/StateOfRepair_TanakornAnongpornyoskul - Tanakorn [Ice] Anongpornyoskul_page2_img7.jpeg",
		"./images/StateOfRepair_TanakornAnongpornyoskul - Tanakorn [Ice] Anongpornyoskul_page3_img1.jpeg",
		"./images/Supernatural Sonorous Territories_Jirapat Taweesin - Jirapat Taweesin_page1_img1.jpeg",
		"./images/Supernatural Sonorous Territories_Jirapat Taweesin - Jirapat Taweesin_page2_img1.jpeg",
		"./images/Supernatural Sonorous Territories_Jirapat Taweesin - Jirapat Taweesin_page2_img2.jpeg",
		"./images/Supernatural Sonorous Territories_Jirapat Taweesin - Jirapat Taweesin_page2_img3.jpeg",
		"./images/Supernatural Sonorous Territories_Jirapat Taweesin - Jirapat Taweesin_page2_img4.jpeg",
		"./images/Supernatural Sonorous Territories_Jirapat Taweesin - Jirapat Taweesin_page2_img5.jpeg",
		"./images/Supernatural Sonorous Territories_Jirapat Taweesin - Jirapat Taweesin_page2_img6.jpeg",
		"./images/Supernatural Sonorous Territories_Jirapat Taweesin - Jirapat Taweesin_page3_img2.jpeg",
		"./images/Supernatural Sonorous Territories_Jirapat Taweesin - Jirapat Taweesin_page3_img5.jpeg",
		"./images/Supernatural Sonorous Territories_Jirapat Taweesin - Jirapat Taweesin_page3_img6.jpeg"

		];

	var randomIndex = Math.floor(Math.random() * imageList.length);
	  var selectedImage = imageList[randomIndex];
	  
	  // Update the display and trigger animation
	  const studentImage = document.querySelector('.studentimage');
	  studentImage.innerHTML = selectedImage.split('/').pop();
	  
	  // Trigger animation by removing and re-adding the class
	  studentImage.classList.remove('bg-animate');
	  // Force a browser reflow to ensure the animation runs again
	  void studentImage.offsetWidth;
	  studentImage.classList.add('bg-animate');
	  
	  return selectedImage;
}






	/*
	* Loads a texture and updates the screen material texture uniform
	*/
	function loadTexture(imageFileName) {
		var loader = new THREE.TextureLoader();

		loader.load(imageFileName, function(texture) {
			texture.minFilter = THREE.LinearFilter;
			texture.magFilter = THREE.LinearFilter;
			imgTexture = texture;
			materialScreen.map = imgTexture;
			materialScreen.needsUpdate = true;
		});
	}

	/*
	* Animates the sketch
	*/
function animate() {
		requestAnimationFrame(animate);
		
		// Begin monitoring this frame
		stats.begin();
		
		// Render scene
		render();
		
		// End monitoring
		stats.end();
	}	

	/*
	* Renders the sketch
	*/
	function render() {
		// Wait until the image texture is loaded
		if (materialScreen.map) {
			// Start rendering the screen scene on the first render target
			if (!uniforms.u_texture.value) {
				renderer.render(sceneScreen, camera, renderTarget1);
			}

			// Update the uniforms
			uniforms.u_time.value = clock.getElapsedTime();
			uniforms.u_frame.value += 1.0;
			uniforms.u_texture.value = renderTarget1.texture;

			// Render the shader scene
			renderer.render(sceneShader, camera, renderTarget2);

			// Update the screen material texture
			materialScreen.map = renderTarget2.texture;
			materialScreen.needsUpdate = true;

			// Render the screen scene
			renderer.render(sceneScreen, camera);

			// Swap the render targets
			var tmp = renderTarget1;
			renderTarget1 = renderTarget2;
			renderTarget2 = tmp;
		}
	}

	/*
	* Updates the renderer size and the uniforms when the window is resized
	*/
	function onWindowResize(event) {
		// Update the renderer
		renderer.setSize(window.innerWidth, window.innerHeight);

		// Update the render targets
		var size = renderer.getDrawingBufferSize();
		renderTarget1.setSize(size.width, size.height);
		renderTarget2.setSize(size.width, size.height);

		// Update the uniforms
		uniforms.u_resolution.value.set(window.innerWidth, window.innerHeight).multiplyScalar(window.devicePixelRatio);
		uniforms.u_texture.value = null;

		// Start again from the original image texture
		materialScreen.map = imgTexture;
	}

	/*
	* Updates the uniforms when the mouse moves
	*/
	function onMouseMove(event) {
		// Update the mouse uniform
		uniforms.u_mouse.value.set(event.pageX, window.innerHeight - event.pageY).multiplyScalar(
				window.devicePixelRatio);
	}

	/*
	* Updates the uniforms when the touch moves
	*/
	function onTouchMove(event) {
		event.preventDefault();

		// Update the mouse uniform
		uniforms.u_mouse.value.set(event.touches[0].pageX, window.innerHeight - event.touches[0].pageY).multiplyScalar(
				window.devicePixelRatio);
	}
}







