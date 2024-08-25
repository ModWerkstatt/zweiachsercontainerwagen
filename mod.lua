function data()
  return {  
	info = {
		minorVersion = 0,
		severityAdd = "NONE",
		severityRemove = "WARNING", 
		name = _("mod_name"),
		description = _("mod_desc"),
		authors = {
			{
				name = 'jay_',
				role = 'CREATOR',
				text = 'Modell',
				tfnetId = 28954,
			},
			{
		        name = "ModWerkstatt",
		        role = "CREATOR",
		    },  
		},
		params = {		
			{
				key = "lgnsfake",
				name = _("Fake"),
				values = { "No", "Yes", },
				tooltip = _("option_fake_lgns_desc"),
				defaultIndex = 0,
			},		
			{
				key = "soundCheck",
				name = _("sound_check"),
				uiType = "CHECKBOX",
				values = { "No", "Yes", },			
				tooltip = _("option_sound_lgns_desc"),	
				defaultIndex = 1,	
			},
		},
		tags = { "Europe", "vehicle", "freight", "wagon" },
		dependencies = {},
		}, 
		
		runFn = function (settings, modParams)
		local params = modParams[getCurrentModId()]
		
		local hidden = {
			["obbFake.mdl"] = true,
			["60s70s_fake.mdl"] = true,
			["60s70sDB_fake.mdl"] = true,
            ["80s90s_fake.mdl"] = true,   
            ["80s90sDB_fake.mdl"] = true,   
            ["btsk_fake.mdl"] = true,   
            ["db_fake.mdl"] = true,   
            ["dbAlt_fake.mdl"] = true,   
            ["db_fake.mdl"] = true,   
            ["dbAlt_fake.mdl"] = true,   
            ["dbBTSK_fake.mdl"] = true,     
            ["dbCargo_fake.mdl"] = true,    
            ["polzug_fake.mdl"] = true,  
        }

		local modelFilter = function(fileName, data)
			local modelName = fileName:match('/laagss_([^/]*.mdl)')
							or fileName:match('/lgjs_([^/]*.mdl)')
							or fileName:match('/lgns583_([^/]*.mdl)')
							or fileName:match('/lgs_([^/]*.mdl)')
			return (modelName==nil or hidden[modelName]~=true)
		end

        if modParams[getCurrentModId()] ~= nil then
			local params = modParams[getCurrentModId()]
			if params["lgnsfake"] == 0 then
				addFileFilter("model/vehicle", modelFilter)
			end
		else
			addFileFilter("model/vehicle", modelFilter)
		end
	
		local function metadataHandler(fileName, data)
			if params.soundCheck == 0 then
				if fileName:match('/vehicle/waggon/lgjs/lgjs_([^/]*.mdl)') 
				or fileName:match('/vehicle/waggon/lgjs/fake/lgjs_([^/]*.mdl)') 
				or fileName:match('/vehicle/waggon/lgs/lgs_([^/]*.mdl)') 
				or fileName:match('/vehicle/waggon/lgs/fake/lgs_([^/]*.mdl)') 
				or fileName:match('/vehicle/waggon/lgns/lgns583_([^/]*.mdl)') 
				or fileName:match('/vehicle/waggon/lgns/fake/lgns583_([^/]*.mdl)') 
				or fileName:match('/vehicle/waggon/laags/laagss_([^/]*.mdl)') 
				or fileName:match('/vehicle/waggon/laags/fake/laagss_([^/]*.mdl)') 
				then
					data.metadata.railVehicle.soundSet.name = "waggon_freight_old"
				end
			end
			return data
		end

		addModifier( "loadModel", metadataHandler )
	end,
}
end
