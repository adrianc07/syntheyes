-- ImagePlane v1.4 for 3dsmax 4-10
-- (c) 2002-2007 Martin Breidt (martin@breidt.net)
--
-- Synopsis:
-- A scripted object plugin that creates a 3D imageplane for a given camera
--
-- About:
-- The imageplane will adjust correctly to the camera FOV (taking image and pixel aspect
-- into account), it will stay at the specified distance to the camera (animatable), will 
-- always face the camera and fill the visible area 100%. 
-- It is useful as a replacment for background images as the imageplane moves right in 3D 
-- space and can both occlude other 3D objects and be occluded by them. 
-- It can be mapped with a 100% self-illuminated material that has an image sequence in 
-- the diffuse slot and the corresponding alpha channel in the opacity slot; this can be 
-- displayed directly in the viewports and is quite useful for layouting set extensions
-- when combining real footage with CG. 
--
-- Installation:
-- Just copy the file to <3dsmaxdir>\scripts\startup\ (or any any other directory 
-- specified under "Customize > Configure Paths > General > Startup Scripts")  and 
-- restart MAX. You'll find the new object type in the "Create" Tab under 
-- "Geometry > MB Objects". Note: As this is an object plugin, you'll need to copy 
-- this file if you want to load a scene with imageplanes on another machine. Otherwise
-- you'll get a "Missing DLL" error.
--
-- Usage:
-- Create a new imageplane just like any other geometric object by click-dragging in any
-- viewport. Next, hit the "Pick" button to assign a camera for the imageplane. This will
-- align the imageplane with the camera. After creation, any manual transformation of the 
-- imageplane will be locked. You can adjust the distance between the imageplane and the 
-- camera with the "Distance" attribute. Length and Width Segs controll the amount of 
-- segments in the imageplane. Offset and Scale allow for fine-adjustments of the placement
-- of the imageplane. All values are animatable and scriptable. 
--
-- Known problems:
-- * Currently only works correctly for non-orthographic cameras (ortho cameras will not
--   be available for picking)
-- * After changing render settings, the imageplanes will only update when the distance 
--   parameter is changed (the value can be set to the same value as before). To update 
--   multiple image planes automatically, use the following code:
--
--   for ip in $objects where (classOf ip == ImagePlane) do ip.distance = ip.distance
-- 
-- * Instancing ImagePlanes is NOT A GOOD IDEA!!! Use copies instead.
-- * Only supports default 3ds Max cameras; does not support Vray cameras, for example.
--
-- History:
-- v1.0 - initial release
-- v1.1 - fixed stupid bug with rolled cameras 
-- v1.2 - bug fix for error when reloading ImagePlane objects; ImagePlanes now do not 
--        cast nor receive shadows; pick filter will not accept ortho cameras
-- v1.3 - ImagePlane non-renderable by default; added buttons for quickly changing box
--        and renderable flags
-- v1.4 - fixed a bug when Vray cameras were present

plugin geometry ImagePlane name:"ImagePlane" 
classID:#(0x78f18d80, 0x790190bc)
category:"MB Objects"
extends:Plane
replaceUI:true
(
	fn cam_filter obj = (
		(superClassof obj==camera) and (hasProperty obj "fov") and (hasProperty obj "orthoProjection")
	)
	
	fn fmax val1 val2 = if val1 > val2 then val1 else val2 

	fn getNodes obj =
	(
		for n in (refs.dependents obj) where ((isValidNode n) and n.baseobject == obj) collect n
	)

	fn GetCamVFOV theCamera = 
	( 
		local r_aspect=(renderWidth*renderPixelAspect as float)/renderHeight 
		2.*atan(tan(theCamera.fov/2.)/r_aspect) 
	) 

	local this_node

	parameters main rollout:param_ro
	(
		Camera_Node type:#node ui:cam_pb
		Distance type:#worldUnits animatable:true default:100 ui:dist_spin 
		LengthSegs type:#integer animatable:true default:4 ui:lengthseg_spin
		WidthSegs type:#integer animatable:true default:4 ui:widthseg_spin
		Offset_U type:#worldUnits animatable:true default:0 ui:u_off_spin
		Offset_V type:#worldUnits animatable:true default:0 ui:v_off_spin
		Scale_U type:#worldUnits animatable:true default:1 ui:u_scale_spin
		Scale_V type:#worldUnits animatable:true default:1 ui:v_scale_spin
		
		on distance set dist do
		(	
			if (camera_node != undefined) then 
			(	
				-- adjust width and height
				hfov = camera_node.fov
				vfov = GetCamVFOV camera_node
				w = dist * tan(hfov/2)
				l = dist * tan(vfov/2)
				delegate.width = 2*w*scale_u
				delegate.length = 2*l*scale_v

				if (this_node == undefined) then this_node = (getNodes this)[1]

				-- correct orientation
				this_node.transform = camera_node.transform
				this_node.parent = camera_node
				
				-- move to correct position
				in coordsys camera_node ( this_node.pos = [offset_u, offset_v, -dist] )				
			)
		)

		-- delegate plane subdivisions after checking for a min val of 1
		on lengthsegs set val do delegate.lengthsegs = fmax val 1
		on widthsegs set val do delegate.widthsegs = fmax val 1
		
		-- call distance change handler for updating offset and scale
		on offset_u set val do this.distance = this.distance
		on offset_v set val do this.distance = this.distance
		on scale_u set val do this.distance = this.distance
		on scale_v set val do this.distance = this.distance
	)
	
	rollout param_ro "Image Plane Parameters"
	(
		group "Camera" (
			label cam_label "  <none>  " align:#left across:2
			pickButton cam_pb "Pick" message:"Pick camera for imageplane" filter:cam_filter tooltip:"Click to select camera" width:50 align:#right offset:[0,-5]
		)
		spinner dist_spin "Distance:" range:[0,1e32,100] type:#worldUnits
		spinner lengthseg_spin "Length Segs:" range:[1,100,4] type:#integer
		spinner widthseg_spin "Width Segs:" range:[1,100,4] type:#integer
		group "Offset" (
			spinner u_off_spin "U:" range:[-1e32,1e32,0] type:#worldUnits across:2 width:70 offset:[-14,0]
			spinner v_off_spin "V:" range:[-1e32,1e32,0] type:#worldUnits width:70 offset:[-10,0]
		)
		group "Scale" (
			spinner u_scale_spin "U:" range:[0,100,1] type:#worldUnits across:2 width:70 offset:[-14,0] scale:0.01
			spinner v_scale_spin "V:" range:[0,100,1] type:#worldUnits width:70 offset:[-10,0] scale:0.01
		)
		group "Toggles" (
			checkbutton render_tgl "Renderable" width:62 across:2 toolTip:"Press to toggle 'Renderable' property"
			checkbutton box_tgl "Box mode" width:62 toolTip:"Press to toggle 'Box Display'"
		)		
		
		on cam_pb picked obj do
		(
			-- hack: call distance change event handler for updating imageplane
			this.distance = this.distance				
		)

		on render_tgl changed state do 
		(
			this_node.renderable = state
		)

		on box_tgl changed state do 
		(
			this_node.boxmode = state
		)
		
		on param_ro open do
		(
			if (camera_node != undefined) then cam_label.text = camera_node.name
			if (this_node != undefined) then (
				render_tgl.checked = this_node.renderable
				box_tgl.checked = this_node.boxmode
			)
		)
	)
	
	rollout about_ro "About" rolledUp:true
	(
		label la "ImagePlane v1.4"
		label lb "(c) 2007 Martin Breidt"
	)

	tool create 
	( 
		on mousePoint click do 
			case click of 
			( 
				1: (
						mynodes = getNodes this
						-- store object node in local variable for further use
						-- this is potentially dangerous when ImagePlane object is instanced
						this_node = mynodes[1]
						nodeTM.translation = gridPoint 
						this_node.wirecolor = [141,7,58]
						this_node.backfacecull = false
						this_node.castShadows = false
						this_node.receiveShadows = false
						this_node.renderable = false
					)
				2: (
						-- do inital setup, then stop creation
						delegate.mapCoords = on
						setTransformLockFlags this_node #all
	
	--					cb_string = "for ip in $objects where (classOf ip == ImagePlane) do ip.distance = ip.distance"
	--					callbacks.removeScripts id:#ImagePlaneCB
	--					callbacks.addScript #renderParamsChanged cb_string id:#ImagePlaneCB persistent:true
						#stop 
				)
					
			) 
		on mouseMove click do 
			if click == 2 then (
				r_asp = ((renderWidth*renderPixelAspect as float)/renderHeight)
				
				x = (abs gridDist.x)
				y = (abs gridDist.y)
				
				-- use x as width if x is dominant, otherwise use y as length
				if (x >= y*r_asp) then ( w = 2 * x; l = w / r_asp )
				if (x < y*r_asp) then ( l = 2 * y; w = l * r_asp )
								
				delegate.width = w
				delegate.length = l
			)
	) 

)
