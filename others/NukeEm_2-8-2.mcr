-- Nuke 'Em v2.8
-- Gavin Greenwalt (im.thatoneguy@gmail.com) and Guy Paquin
-- [:|]  Straightface Studios LLC 2009

-- Code from max2nuke a chanfile and obj exporter v.03 used with permission from christian pundschus (mondochiba) suki@gmx.net 

macroScript NukeEm2dot8
ToolTip:"Nuke 'Em 2.8.2"
buttontext:"Nuke 'Em 2.8"
category:"NukeEm"
(
try(destroydialog nukeEmDialog)catch()
fn safestring stringvar =
(
	stringvar = filterstring stringvar " .|/\<>;:+=*&^%$#@!(){}][~`?\"'"
	safevar = ""
	for i =1 to (stringvar.count - 1) do safevar += (stringvar[i]+"_")
	safevar += stringvar[stringvar.count]
	safevar
)
--VARIABLES
struct NukeEmStruct (selObj,selObjSettings,selCam,savePath,f_length)
global NukeEm = NukeEmStruct selObj:#() selObjSettings:#()
struct NukeExportLib (
	fn collectObjGeoSettings obj savepath sequence:false=
	(
		if sequence then 
		(
			filepath = (savepath+"\\"+(safestring Obj.name)+"\\Geo\\")+(safestring Obj.name)+"_%04d.obj"
		)
		else
		(
			filepath = (savepath+"\\"+(safestring Obj.name)+"\\Geo\\")+(safestring Obj.name)+"_0000.obj"
		)

		exportData = stringstream ""
		format "	file \"%\"\n" (substitutestring filepath "\\" "/")	to:exportData		-- Switch slash direction for nuke.							
		format "	read_texture_w_coord false\n" 								to:exportData		
		exportData
	),

	fn collectReadSettings filepath =
	(
		openimg = openbitmap filepath
		exportData = stringstream ""
		format "	file \"%\"\n" (substitutestring filepath "\\" "/")	to:exportData		-- Switch slash direction for nuke.		)
		format "format \"% % 0 0 % % 1 \"\n" openimg.width openimg.height openimg.width openimg.height	to:exportData
		exportData
	),

	fn collectConstantSettings colorvar channels:"rgba"=
	(
		colorvar /= 255
		exportData = stringstream ""
		format "channels %\n" (channels) to:exportData
		format "color {% % % %}\n" colorvar.r colorvar.g colorvar.b colorvar.a to:exportData
		exportData
	),

	fn CreateNukeNode NodeType NodeName CustomSettings NodePos:[0,0] inputnum:#null= (
		ExportData = Stringstream ""
		
		format "\n% { \n" NodeType to:ExportData
		format "%" (if inputnum != #null then ("	inputs "+(inputnum as string)+"\n") else ("")) to:ExportData
		format "	name % \n " NodeName to:ExportData
		format "	xpos % \n" (NodePos.x as integer) to:ExportData
		format "	ypos % \n" (NodePos.y as integer)to:ExportData
		for i=1 to CustomSettings.count do (format "%" (CustomSettings[i] as string) to:ExportData) -- Add any other pre-formatted node settings
		format "}\n" to:ExportData	
		
		ExportData
	),

	fn collectCameraInfo f_length=
	(
				exportData = stringstream ""
				local hap=GetRendApertureWidth() as string
				local vap=(GetRendApertureWidth()/GetRendImageAspect()) as string

				format "	focal %\n" f_length to:exportData
				format "	haperture %\n" hap to:exportData
				format "	vaperture %\n" vap to:exportData
				ExportData
	),

	fn collectTransformData objNode iscamera:false rotOrder:"XZY" xformOrder:"SRT" framerange:[0,100]=
	(
		struct exportDataStruct (NukeScript, CamTransform, Transform)
		struct camTransformStruct (fov, hap, vap)
		ExportData = ExportDataStruct NukeScript:(stringstream "") Transform:#() CamTransform:#()
		-- Collect Transform Data
		cf = slidertime
		for t in framerange.x to framerange.y do 
		(
			slidertime = t 
			if iscamera do 
			(
				local hap = GetRendApertureWidth()
				local vap = (GetRendApertureWidth()/GetRendImageAspect())
				append ExportData.CamTransform (camTransformStruct fov:objNode.curfov hap:hap vap:vap)
			)
			append ExportData.Transform objNode.transform
		)

		slidertime = cf

		format "		xform_order %
	rot_order %
	translate {\n		" xformOrder rotOrder to:exportData.NukeScript

		-- Begin Transform Output -- 
		
		-- X
		format "{curve " to:exportData.NukeScript
		for j =1 to ExportData.Transform.count do format "x% % " (j - 1 + framerange.x) ExportData.Transform[j].pos.x to:exportData.NukeScript
		format "}\n		" to:exportData.NukeScript
		-- Z
		format "{curve " to:exportData.NukeScript
		for j =1 to ExportData.Transform.count do format "x% % " (j - 1 + framerange.x) ExportData.Transform[j].pos.z to:exportData.NukeScript
		format "}\n		" to:exportData.NukeScript
		-- Y
		format "{curve " to:ExportData.NukeScript
		for j =1 to ExportData.Transform.count do format "x% % " (j - 1 + framerange.x) (ExportData.Transform[j].pos.y*-1) to:exportData.NukeScript
		format "}\n	" to:exportData.NukeScript
		
		format "}\n	" to:exportData.NukeScript 
		
		-- Begin Rotation Output -- 
		format "rotate {\n		" to:exportData.NukeScript 
		for i = 1 to rotOrder.count do
		(
			if rotOrder[i] == "X" then
			(
				-- X
				if iscamera then 
				(
					format "{curve " to:ExportData.NukeScript
					for j =1 to ExportData.Transform.count do format "x% % "  (j - 1 + framerange.x) ((quatToEuler ExportData.Transform[j].rotation).x-90) to:exportData.NukeScript
					format "}\n		" to:exportData.NukeScript
				)
				else 
				(
					format "{curve " to:ExportData.NukeScript
					for j =1 to ExportData.Transform.count do format "x% % "  (j - 1 + framerange.x) ((quatToEuler ExportData.Transform[j].rotation).x) to:exportData.NukeScript
					format "}\n		" to:exportData.NukeScript
				)
			)
			else if rotOrder[i] == "Z" then
			(
				-- Z
				format "{curve " to:ExportData.NukeScript
				for j =1 to ExportData.Transform.count do format "x% % "  (j - 1 + framerange.x) (quatToEuler ExportData.Transform[j].rotation).z to:exportData.NukeScript
				format "}\n		" to:exportData.NukeScript
			)
			else if rotOrder[i] == "Y" then
			(
				-- Y
				format "{curve " to:ExportData.NukeScript
				for j =1 to ExportData.Transform.count do format "x% % "  (j - 1 + framerange.x) (((quatToEuler ExportData.Transform[j].rotation).y)*-1) to:exportData.NukeScript
				format "}\n"	to:exportData.NukeScript
			)
			else ()
		)
		format "	}"	to:exportData.NukeScript
		ExportData
	),
	
	fn createChanFile TransformData isCamera:false CamTransform:undefined framerange:[0,100]=
	(
		chanData = stringstream ""
		for i = 1 to TransformData.count do
		(
			
			format "%  %  %  %  %  %  %" \
				((i - 1 + framerange.x) as string) \
				TransformData[i].pos.x \
				TransformData[i].pos.z \
				(TransformData[i].pos.y*-1) \
				((quatToEuler TransformData[i].rotation).x) \
				((quatToEuler TransformData[i].rotation).z) \
				((quatToEuler TransformData[i].rotation).y*-1) \				
				to:chanData
			if isCamera do
			(
				format " % % %" \
					CamTransform[i].fov\
					CamTransform[i].hap\
					CamTransform[i].vap\
					to:chanData
			)
			format "\n" to:chanData
		)
		chanData
	),

	fn getDiffuseNode DiffuseObj NodePosXY:[100,0] =
	(
		objdiffuse = undefined
		objopacity = undefined
		
		try
		(
			try
			(
				if DiffuseObj.material.diffusemap.bitmap.filename != undefined then
				(
					objdiffuse = DiffuseObj.material.diffusemap.bitmap.filename
				)
				else
				(
					objdiffuse = #solidcolor
				)
			)
			catch
			(
				objdiffuse = #solidcolor
			)
		)
		catch
		(
			objdiffuse = #solidcolor
		)
		
		try
		(
			objopacity = DiffuseObj.material.opacitymap.bitmap.filename
		)
		catch
		(
			objopacity = #null
		)
		
		
		if objdiffuse == #solidcolor then
		(
			try(
				objdiffuse = NukeExportLib.CreateNukeNode "Constant" ((safestring DiffuseObj.name)+"_Diffuse_Map") #(NukeExportLib.collectConstantSettings (DiffuseObj.material.diffuse)) nodepos:[NodeposXY.x+(if objopacity != #null then 50 else 0),NodeposXY.y-35]  inputnum:0
			)
			catch
			(
				objdiffuse = NukeExportLib.CreateNukeNode "Constant" ((safestring DiffuseObj.name)+"_Diffuse_Map") #(NukeExportLib.collectConstantSettings (DiffuseObj.wirecolor)) nodepos:[NodeposXY.x+(if objopacity != #null then 50 else 0),NodeposXY.y-35] inputnum:0
			)
		)
		else
		(
			objdiffuse = NukeExportLib.CreateNukeNode "Read" ((safestring DiffuseObj.name)+"_Diffuse_Map") #(NukeExportLib.collectReadSettings (DiffuseObj.material.diffusemap.bitmap.filename)) nodepos:[NodeposXY.x+50,NodeposXY.y-35] inputnum:0	
		)

		if objopacity != #null then
		(
			objopacity = NukeExportLib.CreateNukeNode "Read" ((safestring DiffuseObj.name)+"_Opacity_Map") #(NukeExportLib.collectReadSettings (objopacity)) nodepos:[NodeposXY.x-50,NodeposXY.y-35] inputnum:0
			format (objdiffuse as string) to:objopacity
			if DiffuseObj.material.opacitymap.MonoOutput == 0 then
			(
				format ((NukeExportLib.CreateNukeNode "Copy" ((safestring DiffuseObj.name)+"_Copy") #(" from0 rgba.red\nto0 rgba.alpha\n") nodepos:[NodeposXY.x,NodeposXY.y+50] inputnum:2) as string) to:objopacity
			)
			else
			(
				format ((NukeExportLib.CreateNukeNode "Copy" ((safestring DiffuseObj.name)+"_Copy") #(" from0 rgba.alpha\nto0 rgba.alpha\n") nodepos:[NodeposXY.x,NodeposXY.y+50] inputnum:2) as string) to:objopacity
			)
			format ((NukeExportLib.CreateNukeNode "Premult" ((safestring DiffuseObj.name)+"_Premult") #() nodepos:[NodeposXY.x,NodeposXY.y+100] inputnum:1) as string) to:objopacity
		)
		else (objopacity = objdiffuse)
		objopacity
	),
	
	fn getEnvironmentNode NodePosXY=
	(
		if UseEnvironmentMap then
		(
			objdiffuse = NukeExportLib.CreateNukeNode "Read" ("Environment_Map") #(NukeExportLib.collectReadSettings (EnvironmentMap.bitmap.filename)) nodepos:NodeposXY inputnum:0	
			
		)
		else
		(
			objdiffuse = NukeExportLib.CreateNukeNode "Constant" ("Environment_Color") #(NukeExportLib.collectConstantSettings (backgroundcolor)) nodepos:NodeposXY inputnum:0
		)
		objdiffuse
	),
	
	fn ExportGeo obj exportpath format:#obj sequence:false framerange:[0,100]=
	(
		completiontick =undefined
		if not sequence then 
		(
			framerange = [0,0]
			completiontick = (1 as float/(NukeEm.selObj.count))*100
		)
		else
		(
			completiontick = (1 as float/(NukeEmDialog.CustomGeoEnd.value-NukeEmDialog.CustomGeoStart.value*NukeEm.selObj.count))*100
		)
		exportlength = (framerange.y-framerange.x)
		cf = slidertime
		for t in framerange.x to framerange.y do 
		(
			slidertime = t 
			if t > -1 then
			(
				paddedframenum = substring (((t+10000) as integer)as string) 2 5
			)
			else
			(
				paddedframenum = "-"+(substring (((t-10000) as integer)as string) 4 5)
			)
			objfile = exportpath+"\\"+(safestring obj.name)+"_"+paddedframenum+".obj"
			if doesFileExist objfile then deletefile objfile
			select obj
			selobjpos = obj.pos
			obj.pos = [0,0,0]
			selobjrot = obj.rotation
			obj.rotation = (quat 0 0 0 1)
			exportFile objfile  #noPrompt selectedOnly:true
			obj.rotation = selobjrot
			obj.pos = selobjpos
			deselect $
			NukeEmDialog.prgBar.value += completiontick
		)
		slidertime = cf
	)
)

global NukeEm = NukeEmStruct selObj:#() selObjSettings:#()
global NukeEmDialog

fn cam_filt obj = (superClassOf obj == camera)
fn geo_filt obj = (superClassOf obj == geometryclass or superClassOf obj == helper)

rollout nukeEmDialog "Nuke 'Em v2.81" width:450 height:400
(
	groupbox NukeEmSetup "Object Setup" pos:[5,5] width:440 height:210
		button pickcam "Select Camera" pos:[10,40] width:122 height:27
		button selObjects "Select Objects" pos:[10,70] width:122 height:27
		button outputPathButton "Output Path" pos:[10,100] width:122 height:27
			
		checkbox CustomTimeCheck "Custom Frame Range" pos:[10,145] enabled:true
			
		label CustomStartLabel "S:" pos:[20,165] enabled:false
		spinner CustomStart "" pos:[32,165] range:[-9999,9999,2] enabled:false width:50 type:#integer
		button resetCustomS "reset" pos:[82,165] width:50 height:16 enabled:false
			
		label CustomEndLabel "E:" pos:[20,185] enabled:false
		spinner CustomEnd "" pos:[32,185] range:[-9999,9999,2] enabled:false width:50 type:#integer
		button resetCustomE "reset" pos:[82,185] width:50 height:16 enabled:false
			
			
		multilistbox SelectedObjectsLB "Objects" width:148 height:12 pos:[137,23] enabled:false
			
		groupbox ObjectExportGroup "Object Export Settings" pos:[286,33] width:154 height:168
			
			label GeoTypeLabel "File Format:" pos:[324,55] enabled:false
			dropdownlist GeoTypeDrop ""  pos:[385,50] width:50 items:#("OBJ","FBX") enabled:false
			
			label TransformLabel "Transform Order:" pos:[297,78] enabled:false
			dropdownlist TransformOrderDrop ""  pos:[385,75] width:50 items:#("SRT","STR","RST","RTS","TSR","TRS") enabled:false
			label RotationLabel "Rotation Order:" pos:[305,103] enabled:false
			dropdownlist RotationOrderDrop ""  pos:[385,100] width:50 items:#("XYZ","XZY","YXZ","YZX","ZXY","ZYX") enabled:false selection:2
			checkbox GeoSeqCheck "Geometry Sequence" pos:[300,125] 
			checkbox CustomGeoTimeCheck "Custom Geo-Seq Range" pos:[300,145] enabled:false
			label CustomGeoStartLabel "S:" pos:[300,165] enabled:false
			spinner CustomGeoStart "" range:[-9999,9999,2] pos:[310,165] enabled:false width:50 type:#integer
			label CustomGeoEndLabel "E:" pos:[372,165] enabled:false
			spinner CustomGeoEnd "" range:[-9999,9999,2] pos:[382,165] enabled:false width:50 type:#integer
			button resetCustomGeoS "reset" pos:[310,180] width:50 height:15 enabled:false
			button resetCustomGeoE "reset" pos:[382,180] width:50 height:15 enabled:false
		
		
	groupbox OutputGroup "Output Settings" pos:[5,220] height:125 width:440
		checkbox sceneGenerator "Create Scene Nodes" checked:true pos:[15,240] teooltip:"Create scene and scanline render nodes in Nuke."
		checkbox textureObjectsCheck "Create Shaders" checked:true pos:[15,257] tooltip:"Create scene and scanline render nodes in Nuke."
		checkbox CreateBackdropsCheck "Create Backdrops" enabled:false checked:false pos:[15,274] tooltip:"Create scene and scanline render nodes in Nuke."
		checkbox CreateEnvironmentCheck "Create Environment" checked:true pos:[15,291] tooltip:"Create scene and scanline render nodes in Nuke."
			
		checkbox NukeScriptCheck "Output Nuke Script" checked:false pos:[158,240] teooltip:"Create scene and scanline render nodes in Nuke."
		checkbox ShowNukeScriptCheck "Show Nuke Script" checked:false pos:[158,257] tooltip:"Create scene and scanline render nodes in Nuke."
		checkbox ChanFilesCheck "Output Chan Files" enabled:true checked:false pos:[158,274] tooltip:"Create scene and scanline render nodes in Nuke."
		checkbox GeoFilesCheck "Output Geo Files" enabled:true checked:true pos:[158,291] tooltip:"Create scene and scanline render nodes in Nuke."
			
		button nukeEm_btn "Nuke 'Em!" pos:[280,240] width:155 height:67 enabled:false tooltip:"Copies animation data to clipboard to be pasted in Nuke."
			
		progressBar PrgBar "ProgressBar" pos:[15,321] width:420 height:15 
		
	--subrollout SubUtilityRollout "Utilities" width:450 pos:[0,357] height:60
	
	on NukeEmDialog open do
	(
		CustomGeoStart.value = CustomStart.value = animationRange.start
		CustomGeoEnd.value = CustomEnd.value = animationRange.end
	)
	
	on NukeEmDialog close do
	(
		NukeEmStruct = undefined
		NukeEm = undefined
		NukeExportLib = undefined
		geo_filt = undefined
		cam_filt = undefined
		gc()
	)
	
	on pickcam pressed do 
	(
		NukeEm.selCam = selectByName title: "Select a Camera" Filter:cam_filt single:true;
		If NukeEm.selCam != undefined do
		(
			if classof NukeEm.selCam == Main_Camera then
			(
				NukeEm.f_length = cameraFOV.FOVtoMM NukeEm.selCam.lens.fov 
				NukeEm.selCam.lens.fov_type=1
			)
			else
			(
				NukeEm.f_length = cameraFOV.FOVtoMM NukeEm.selCam.fov 
				NukeEm.selCam.fovType=2
			)
			pickcam.text = (safestring NukeEm.selCam.name)
			nukeEm_btn.enabled = true
		)
	)
	
	on selObjects pressed do 
	(
		selObjList=selectByName title: "Select single or multiple objects" Filter:geo_filt;
		if selObjList != undefined then NukeEm.selObj = selObjList
		if NukeEm.selObj.count >0  then
		(
			selObjects.text = (NukeEm.selObj.count as string)+" Objects Selected"
		)
		NukeEmDialog.SelectedObjectsLB.items = for o in NukeEm.selObj collect (safestring o.name)
		--nukeemdialog.selectedobjectslb.selection = #{1..(nukeemdialog.selectedobjectslb.items.count)}
		nukeEm_btn.enabled = true
	)
	
	on OutputPathButton pressed do
	(
		OutputPathVar = getSavePath initialDir:maxFilePath
		if OutputPathVar != undefined do
		(
			NukeEm.SavePath = OutputPathVar
			nukeEm_btn.enabled = true
			OutputPathVar = filterstring OutputPathVar "\\"
			OutputPathButton.text = "...\\"+(OutputPathVar[OutputPathVar.count])
		)
	)
	
	on CustomTimeCheck changed c do
	(
		if c == true then
		(
			CustomStartLabel.enabled = CustomStart.enabled = resetCustomS.enabled = CustomEndLabel.enabled = CustomEnd.enabled = resetCustomE.enabled = true
		)
		else
		(
			CustomStartLabel.enabled = CustomStart.enabled = resetCustomS.enabled = CustomEndLabel.enabled = CustomEnd.enabled = resetCustomE.enabled = false
		)
	)
	
	on CustomStart changed c do
	(
		if not customGeoTimeCheck.checked do (customGeoStart.value = c)
	)
	
	on CustomEnd changed c do
	(
		if not customGeoTimeCheck.checked do (customGeoEnd.value = c)
	)
	
	on GeoSeqCheck changed c do
	(
		if c == true then
		(
			CustomGeoTimeCheck.enabled = true
			if CustomGeoTimeCheck.checked == true then
			(
				CustomGeoStartLabel.enabled = CustomGeoStart.enabled = CustomGeoEndLabel.enabled = CustomGeoEnd.enabled = resetCustomGeoS.enabled = resetCustomGeoE.enabled = true
			)
			else 
			(
				CustomGeoStartLabel.enabled = CustomGeoStart.enabled = CustomGeoEndLabel.enabled = CustomGeoEnd.enabled = resetCustomGeoS.enabled = resetCustomGeoE.enabled = false
			)
		)
		else
		(
			CustomGeoTimeCheck.enabled = CustomGeoStartLabel.enabled = CustomGeoStart.enabled = CustomGeoEndLabel.enabled = CustomGeoEnd.enabled = resetCustomGeoS.enabled = resetCustomGeoE.enabled = false
		)			
	)
	
	on CustomGeoTimeCheck changed c do
	(
		if c == true then
		(
			CustomGeoStartLabel.enabled = CustomGeoStart.enabled = CustomGeoEndLabel.enabled = CustomGeoEnd.enabled = resetCustomGeoS.enabled = resetCustomGeoE.enabled = true
		)
		else 
		(
			CustomGeoStartLabel.enabled = CustomGeoStart.enabled = CustomGeoEndLabel.enabled = CustomGeoEnd.enabled = resetCustomGeoS.enabled = resetCustomGeoE.enabled = false
		)
	)
	
	on resetCustomS pressed do
	(
		customStart.value = animationrange.start
	)
	
	on resetCustomE pressed do
	(
		customEnd.value = animationrange.End
	)
	
	on resetCustomGeoS pressed do
	(
		customGeoStart.value = animationrange.start
	)
	
	on resetCustomGeoE pressed do
	(
		customGeoEnd.value = animationrange.End
	)
	
	on nukeEm_btn pressed do
	(
		proceed = true
		if NukeEm.Savepath == undefined do
		(
			if GeoFilesCheck.checked and ((for o in NukeEm.selObj where classof o != target collect o).count) > 0 do proceed = false
			if ChanFilesCheck.checked do proceed = false
			if NukeScriptCheck.checked do proceed = false
		)
		if not proceed then
		(
			messagebox "You are attempting to output files.  Please choose an output path and try again."
		)
		else
		(
			NukeScript = stringstream ""
			disableSceneRedraw()
			cf = slidertime
			local starttime = undefined
			local endtime = undefined
			if NukeEmDialog.CustomTimeCheck.checked then 
			(
				starttime = NukeEmDialog.CustomStart.value
				endtime = NukeEmDialog.CustomEnd.value
				geostarttime = NukeEmDialog.CustomGeoStart.value
				geoendtime = NukeEmDialog.CustomGeoEnd.value
			)
			else
			(
				starttime = animationRange.start
				endtime = animationRange.end
				if NukeEmDialog.customGeoTimeCheck.checked then
				(
					geostarttime = animationRange.start
					geoendtime = animationRange.end
				)
				else
				(
					geostarttime = NukeEmDialog.CustomGeoStart.value
					geoendtime = NukeEmDialog.CustomGeoEnd.value
				)
			)

			if NukeEm.selCam != undefined then
			(
				collectedData = (NukeExportLib.collectTransformData NukeEm.selCam iscamera:true xformOrder:NukeEmDialog.TransformOrderDrop.selected rotOrder:NukeEmDialog.RotationOrderDrop.selected FrameRange:[starttime,endtime])
				format ((NukeExportLib.CreateNukeNode "Camera" (safestring NukeEm.selCam.name) #((CollectedData.NukeScript),(NukeExportLib.collectCameraInfo NukeEm.f_length)) NodePos:[150,100]) as string) to:NukeScript
				format "push [stack 0]\n push [stack 0]\n" to:NukeScript
				
				if NukeEmDialog.ChanFilesCheck.checked do
				(
					chanfile = createfile (NukeEm.SavePath+"\\"+(safestring NukeEm.selCam.name)+".chan")
					format ((NukeExportLib.createChanFile CollectedData.Transform isCamera:true CamTransform:CollectedData.CamTransform FrameRange:[starttime,endtime]) as string) to:chanfile
					close chanfile
				)
				
			)
			
			if NukeEm.selObj.count > 0 then
			(
				gwExportINI = getDir #plugcfg + "\\gw_objexp.ini" 
				GWObjPreset = getINISetting gwExportINI "General" "Preset"
				GWObjFlipZy = getINISetting gwExportINI "Geometry" "FlipZyAxis"
				GWObjExportMat = getINISetting gwExportINI "Material" "UseMaterial"

				setINISetting gwExportINI "General" "Preset" "Nuke"
				setINISetting gwExportINI "Geometry" "FlipZyAxis" "1"
				setINISetting gwExportINI "Material" "UseMaterial" "0"
				
				for i =1 to NukeEm.selObj.count do
				(
					makedir (NukeEm.savepath+"\\"+(safestring NukeEm.selObj[i].name)+"\\")
					CollectedData = (NukeExportLib.collectTransformData NukeEm.selObj[i] xformOrder:NukeEmDialog.TransformOrderDrop.selected rotOrder:NukeEmDialog.RotationOrderDrop.selected FrameRange:[starttime,endtime])
					-- export each object to OBJ file
					NodeXPos = (((0-(NukeEm.selObj.count-1))/2)+(i-1))*200
					if (superclassof NukeEm.selObj[i] == geometryclass and classof NukeEm.selObj[i] != targetobject) do
					(
						makedir (NukeEm.savepath+"\\"+(safestring NukeEm.selObj[i].name)+"\\Geo")
						if NukeEmDialog.GeoFilesCheck.Checked do 
						(
							NukeExportLib.ExportGeo NukeEm.selObj[i] (NukeEm.SavePath+"\\"+(safestring NukeEm.selObj[i].name)+"\\Geo") sequence:NukeEmDialog.GeoSeqCheck.checked format:#obj FrameRange:[geoStartTime,geoEndtime]
						)
						if NukeEmDialog.textureObjectsCheck.checked do
						(
							format ((NukeExportLib.getDiffuseNode NukeEm.selObj[i] nodeposxy:[NodeXPos,-200]) as string) to:NukeScript
						)
						format ((NukeExportLib.CreateNukeNode "ReadGeo" (safestring NukeEm.selObj[i].name) #((substitutestring (NukeExportLib.collectObjGeoSettings NukeEm.selObj[i] NukeEm.savepath sequence:(NukeEmDialog.GeoSeqCheck.checked)) "%" "\%")) nodepos:[NodeXPos, -50] inputnum:(if NukeEmDialog.textureObjectsCheck.checked then #null else 0)) as string) to:NukeScript
					)
					format ((NukeExportLib.CreateNukeNode "TransformGeo" (safestring NukeEm.selObj[i].name) #((CollectedData.nukescript)) nodepos:[NodeXPos, 0] inputnum:(if (superclassof NukeEm.selObj[i] == geometryclass and classof NukeEm.selObj[i] != targetobject) then #null else 0)) as string) to:NukeScript
					if NukeEmDialog.ChanFilesCheck.checked do
					(
						makedir (NukeEm.savepath+"\\"+(safestring NukeEm.selObj[i].name)+"\\chan")
						chanfile = createfile (NukeEm.SavePath+"\\"+(safestring NukeEm.selObj[i].name)+"\\chan\\"+(safestring NukeEm.selobj[i].name)+".chan")
						format ((NukeExportLib.createChanFile CollectedData.Transform FrameRange:[starttime,endtime]) as string) to:chanfile
						close chanfile
					)
				)
				setINISetting gwExportINI "General" "Preset" GWObjPreset
				setINISetting gwExportINI "Geometry" "FlipZyAxis" GWObjFlipZy
				setINISetting gwExportINI "Material" "UseMaterial" GWObjExportMat
			)
			
			if sceneGenerator.checked then
			(
				if NukeEm.selCam != undefined then (inputs = NukeEm.selObj.count+1; renderInputs = 3)			
				else (inputs = NukeEm.selObj.count; renderInputs = 2)
				format "Scene {\ninputs " to:NukeScript
				format "%\n" inputs to:NukeScript
				format"name Scene1\nxpos 0\nypos 100\n}\n" to:NukeScript
				if not NukeEmDialog.CreateEnvironmentCheck.checked then (
					format "push 0\n" to:NukeScript
				)
				else
				(
					format ((NukeExportLib.getEnvironmentNode [-200,100]) as string) to:NukeScript
					format ((NukeExportLib.CreateNukeNode "Reformat" "Render_Output_Size" #("format \""+RenderWidth as string+" "+RenderHeight as string+" 0 0 "+RenderWidth as string+" "+RenderHeight as string+" "+RenderPixelAspect as string+" 3ds_Max_Render\"") nodepos:[-200,200]) as string) to:NukeScript
				)
				format "ScanlineRender {\ninputs " to:NukeScript
				format "%" renderInputs to:NukeScript
				format "\nname ScanlineRender1\nxpos 0\nypos 200\n}" to:NukeScript
			)
			setclipboardText NukeScript as string
			if NukeEmDialog.ShowNukeScriptCheck.checked do
			(
				debug = newscript()
				format "Root {
 inputs 0
 first_frame %
 last_frame %
 fps %
 format \" % % 0 0 % % 1 3dsmax_render\"
}\n" (substring (animationrange.start as string) 1 ((animationrange.start as string).count - 1)) (substring (animationrange.end as string) 1 ((animationrange.end as string).count - 1)) (framerate as string) (RenderWidth as string) (RenderHeight as string) (RenderWidth as string) (RenderHeight as string) to:debug
				
				format (substitutestring (NukeScript as string) "%" "\%") to:debug
			)
			if NukeEmDialog.NukeScriptCheck.checked do
			(
				nukefilename = if maxfilename != "" then (getfilenamefile maxfilename) else ("Untitled")
				nukefilepath = (NukeEm.SavePath+"\\"+NukeFileName+".nk")
				nukefile = createfile nukefilepath
				format "Root {
 inputs 0
 first_frame %
 last_frame %
 fps %
 format \" % % 0 0 % % 1 3dsmax_render\"
}\n" (substring (animationrange.start as string) 1 ((animationrange.start as string).count - 1)) (substring (animationrange.end as string) 1 ((animationrange.end as string).count - 1)) (framerate as string) (RenderWidth as string) (RenderHeight as string) (RenderWidth as string) (RenderHeight as string) to:nukefile
				format (substitutestring (NukeScript as string) "%" "\%") to:nukefile
				close nukefile
			)
			enableSceneRedraw()
			slidertime = cf
			NukeEmDialog.prgBar.value=0
		)
	)-- end NukeEm
)-- end rollout
rollout NukeEmUtilDialog "Utilities" (
	button Utility1Button "Utility 1"
)
rollout NukeEmHelpDialog "Help" (
	button Help1Button "Help"
)

createDialog NukeEmDialog pos:[200,200]

--addsubrollout NukeEmDialog.SubUtilityRollout NukeEmUtilDialog
--addsubrollout NukeEmDialog.SubUtilityRollout NukeEmHelpDialog
)