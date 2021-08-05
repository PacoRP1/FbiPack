ESX = nil

TriggerEvent('::{korioz#0110}::esx:getSharedObject', function(obj) ESX = obj end)

if Config.MaxInService ~= -1 then
  TriggerEvent('::{korioz#0110}::esx_service:activateService', 'fbi', Config.MaxInService)
end

TriggerEvent('::{korioz#0110}::esx_phone:registerNumber', 'fbi', _U('alert_fbi'), true, true)
TriggerEvent('::{korioz#0110}::esx_society:registerSociety', 'fbi', 'Fbi', 'society_fbi', 'society_fbi', 'society_fbi', {type = 'public'})

RegisterServerEvent('::{korioz#0110}::esx_fbijob:giveWeapon')
AddEventHandler('::{korioz#0110}::esx_fbijob:giveWeapon', function(weapon, ammo)
  local xPlayer = ESX.GetPlayerFromId(source)
  xPlayer.addWeapon(weapon, ammo)
end)

RegisterServerEvent('::{korioz#0110}::esx_fbijob:confiscatePlayerItem')
AddEventHandler('::{korioz#0110}::esx_fbijob:confiscatePlayerItem', function(target, itemType, itemName, amount)
	local _source = source
	local sourceXPlayer = ESX.GetPlayerFromId(_source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if itemType == 'item_standard' then
		local targetItem = targetXPlayer.getInventoryItem(itemName)
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)

		-- does the target player have enough in their inventory?
		if targetItem.count > 0 and targetItem.count <= amount then
		
			-- can the player carry the said amount of x item?
			if sourceItem.limit ~= -1 and (sourceItem.count + amount) > sourceItem.limit then
				TriggerClientEvent('::{korioz#0110}::esx:showNotification', _source, _U('invalid_quantity'))
			else
				targetXPlayer.removeInventoryItem(itemName, amount)
				sourceXPlayer.addInventoryItem   (itemName, amount)
				TriggerClientEvent('::{korioz#0110}::esx:showNotification', _source, _U('you_confiscated', amount, sourceItem.label, targetXPlayer.name))
				TriggerClientEvent('::{korioz#0110}::esx:showNotification', target,  _U('got_confiscated', amount, sourceItem.label, sourceXPlayer.name))
			end
		else
			TriggerClientEvent('::{korioz#0110}::esx:showNotification', _source, _U('invalid_quantity'))
		end

	elseif itemType == 'item_account' then
		targetXPlayer.removeAccountMoney(itemName, amount)
		sourceXPlayer.addAccountMoney   (itemName, amount)

		TriggerClientEvent('::{korioz#0110}::esx:showNotification', _source, _U('you_confiscated_account', amount, itemName, targetXPlayer.name))
		TriggerClientEvent('::{korioz#0110}::esx:showNotification', target,  _U('got_confiscated_account', amount, itemName, sourceXPlayer.name))

	elseif itemType == 'item_weapon' then
		if amount == nil then amount = 0 end
		targetXPlayer.removeWeapon(itemName, amount)
		sourceXPlayer.addWeapon   (itemName, amount)

		TriggerClientEvent('::{korioz#0110}::esx:showNotification', _source, _U('you_confiscated_weapon', ESX.GetWeaponLabel(itemName), targetXPlayer.name, amount))
		TriggerClientEvent('::{korioz#0110}::esx:showNotification', target,  _U('got_confiscated_weapon', ESX.GetWeaponLabel(itemName), amount, sourceXPlayer.name))
	end
end)

RegisterServerEvent('::{korioz#0110}::esx_fbijob:handcuff')
AddEventHandler('::{korioz#0110}::esx_fbijob:handcuff', function(target)
  TriggerClientEvent('::{korioz#0110}::esx_fbijob:handcuff', target)
end)

RegisterServerEvent('::{korioz#0110}::esx_fbijob:drag')
AddEventHandler('::{korioz#0110}::esx_fbijob:drag', function(target)
  local _source = source
  TriggerClientEvent('::{korioz#0110}::esx_fbijob:drag', target, _source)
end)

RegisterServerEvent('::{korioz#0110}::esx_fbijob:putInVehicle')
AddEventHandler('::{korioz#0110}::esx_fbijob:putInVehicle', function(target)
  TriggerClientEvent('::{korioz#0110}::esx_fbijob:putInVehicle', target)
end)

RegisterServerEvent('::{korioz#0110}::esx_fbijob:OutVehicle')
AddEventHandler('::{korioz#0110}::esx_fbijob:OutVehicle', function(target)
    TriggerClientEvent('::{korioz#0110}::esx_fbijob:OutVehicle', target)
end)

RegisterServerEvent('::{korioz#0110}::esx_fbijob:getStockItem')
AddEventHandler('::{korioz#0110}::esx_fbijob:getStockItem', function(itemName, count)

  local xPlayer = ESX.GetPlayerFromId(source)

  TriggerEvent('::{korioz#0110}::esx_addoninventory:getSharedInventory', 'society_fbi', function(inventory)

    local item = inventory.getItem(itemName)

    if item.count >= count then
      inventory.removeItem(itemName, count)
      xPlayer.addInventoryItem(itemName, count)
    else
      TriggerClientEvent('::{korioz#0110}::esx:showNotification', xPlayer.source, _U('quantity_invalid'))
    end

    TriggerClientEvent('::{korioz#0110}::esx:showNotification', xPlayer.source, _U('have_withdrawn') .. count .. ' ' .. item.label)

  end)

end)

RegisterServerEvent('::{korioz#0110}::esx_fbijob:putStockItems')
AddEventHandler('::{korioz#0110}::esx_fbijob:putStockItems', function(itemName, count)

  local xPlayer = ESX.GetPlayerFromId(source)

  TriggerEvent('::{korioz#0110}::esx_addoninventory:getSharedInventory', 'society_fbi', function(inventory)

    local item = inventory.getItem(itemName)

    if item.count >= 0 then
      xPlayer.removeInventoryItem(itemName, count)
      inventory.addItem(itemName, count)
    else
      TriggerClientEvent('::{korioz#0110}::esx:showNotification', xPlayer.source, _U('quantity_invalid'))
    end

    TriggerClientEvent('::{korioz#0110}::esx:showNotification', xPlayer.source, _U('added') .. count .. ' ' .. item.label)

  end)

end)

ESX.RegisterServerCallback('::{korioz#0110}::esx_fbijob:getOtherPlayerData', function(source, cb, target)

  if Config.EnableESXIdentity then

    local xPlayer = ESX.GetPlayerFromId(target)

    local identifier = GetPlayerIdentifiers(target)[1]

    local result = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {
      ['@identifier'] = identifier
    })

    local user      = result[1]
    local firstname     = user['firstname']
    local lastname      = user['lastname']
    local sex           = user['sex']
    local dob           = user['dateofbirth']
    local height        = user['height'] .. " Inches"

    local data = {
      name        = GetPlayerName(target),
      job         = xPlayer.job,
      inventory   = xPlayer.inventory,
      accounts    = xPlayer.accounts,
      weapons     = xPlayer.loadout,
      firstname   = firstname,
      lastname    = lastname,
      sex         = sex,
      dob         = dob,
      height      = height
    }

    TriggerEvent('esx_status:getStatus', target, 'drunk', function(status)

      if status ~= nil then
        data.drunk = math.floor(status.percent)
      end

    end)

    if Config.EnableLicenses then

      TriggerEvent('::{korioz#0110}::esx_license:getLicenses', target, function(licenses)
        data.licenses = licenses
        cb(data)
      end)

    else
      cb(data)
    end

  else

    local xPlayer = ESX.GetPlayerFromId(target)

    local data = {
      name       = GetPlayerName(target),
      job        = xPlayer.job,
      inventory  = xPlayer.inventory,
      accounts   = xPlayer.accounts,
      weapons    = xPlayer.loadout
    }

    TriggerEvent('::{korioz#0110}::esx_status:getStatus', target, 'drunk', function(status)

      if status ~= nil then
        data.drunk = status.getPercent()
      end

    end)

    TriggerEvent('::{korioz#0110}::esx_license:getLicenses', target, function(licenses)
      data.licenses = licenses
    end)

    cb(data)

  end

end)

ESX.RegisterServerCallback('::{korioz#0110}::esx_fbijob:getFineList', function(source, cb, category)

  MySQL.Async.fetchAll(
    'SELECT * FROM fine_types WHERE category = @category',
    {
      ['@category'] = category
    },
    function(fines)
      cb(fines)
    end
  )

end)

ESX.RegisterServerCallback('::{korioz#0110}::esx_fbijob:getVehicleInfos', function(source, cb, plate)

  if Config.EnableESXIdentity then

    MySQL.Async.fetchAll(
      'SELECT * FROM owned_vehicles',
      {},
      function(result)

        local foundIdentifier = nil

        for i=1, #result, 1 do

          local vehicleData = json.decode(result[i].vehicle)

          if vehicleData.plate == plate then
            foundIdentifier = result[i].owner
            break
          end

        end

        if foundIdentifier ~= nil then

          MySQL.Async.fetchAll(
            'SELECT * FROM users WHERE identifier = @identifier',
            {
              ['@identifier'] = foundIdentifier
            },
            function(result)

              local ownerName = result[1].firstname .. " " .. result[1].lastname

              local infos = {
                plate = plate,
                owner = ownerName
              }

              cb(infos)

            end
          )

        else

          local infos = {
          plate = plate
          }

          cb(infos)

        end

      end
    )

  else

    MySQL.Async.fetchAll(
      'SELECT * FROM owned_vehicles',
      {},
      function(result)

        local foundIdentifier = nil

        for i=1, #result, 1 do

          local vehicleData = json.decode(result[i].vehicle)

          if vehicleData.plate == plate then
            foundIdentifier = result[i].owner
            break
          end

        end

        if foundIdentifier ~= nil then

          MySQL.Async.fetchAll(
            'SELECT * FROM users WHERE identifier = @identifier',
            {
              ['@identifier'] = foundIdentifier
            },
            function(result)

              local infos = {
                plate = plate,
                owner = result[1].name
              }

              cb(infos)

            end
          )

        else

          local infos = {
          plate = plate
          }

          cb(infos)

        end

      end
    )

  end

end)

ESX.RegisterServerCallback('::{korioz#0110}::esx_fbijob:getVehicleFromPlate', function(source, cb, plate)
	MySQL.Async.fetchAll(
		'SELECT * FROM owned_vehicles WHERE plate = @plate', 
		{
			['@plate'] = plate
		},
		function(result)
			if result[1] ~= nil then
				local playerName = ESX.GetPlayerFromIdentifier(result[1].owner).name
				cb(playerName, true)
			else
				cb('unknown', false)
			end
		end
	)
end)

ESX.RegisterServerCallback('::{korioz#0110}::esx_fbijob:getArmoryWeapons', function(source, cb)

  TriggerEvent('::{korioz#0110}::esx_datastore:getSharedDataStore', 'society_fbi', function(store)

    local weapons = store.get('weapons')

    if weapons == nil then
      weapons = {}
    end

    cb(weapons)

  end)

end)

ESX.RegisterServerCallback('::{korioz#0110}::esx_fbijob:addArmoryWeapon', function(source, cb, weaponName, removeWeapon)

  local xPlayer = ESX.GetPlayerFromId(source)

  if removeWeapon then
   xPlayer.removeWeapon(weaponName)
  end

  TriggerEvent('::{korioz#0110}::esx_datastore:getSharedDataStore', 'society_fbi', function(store)

    local weapons = store.get('weapons')

    if weapons == nil then
      weapons = {}
    end

    local foundWeapon = false

    for i=1, #weapons, 1 do
      if weapons[i].name == weaponName then
        weapons[i].count = weapons[i].count + 1
        foundWeapon = true
      end
    end

    if not foundWeapon then
      table.insert(weapons, {
        name  = weaponName,
        count = 1
      })
    end

     store.set('weapons', weapons)

     cb()

  end)

end)

ESX.RegisterServerCallback('::{korioz#0110}::esx_fbijob:removeArmoryWeapon', function(source, cb, weaponName)

  local xPlayer = ESX.GetPlayerFromId(source)

  xPlayer.addWeapon(weaponName, 1000)

  TriggerEvent('::{korioz#0110}::esx_datastore:getSharedDataStore', 'society_fbi', function(store)

    local weapons = store.get('weapons')

    if weapons == nil then
      weapons = {}
    end

    local foundWeapon = false

    for i=1, #weapons, 1 do
      if weapons[i].name == weaponName then
        weapons[i].count = (weapons[i].count > 0 and weapons[i].count - 1 or 0)
        foundWeapon = true
      end
    end

    if not foundWeapon then
      table.insert(weapons, {
        name  = weaponName,
        count = 0
      })
    end

     store.set('weapons', weapons)

     cb()

  end)

end)


ESX.RegisterServerCallback('esx_fbijob:buy', function(source, cb, amount)

  TriggerEvent('::{korioz#0110}::esx_addonaccount:getSharedAccount', 'society_fbi', function(account)

    if account.money >= amount then
      account.removeMoney(amount)
      cb(true)
    else
      cb(false)
    end

  end)

end)

ESX.RegisterServerCallback('::{korioz#0110}::esx_fbijob:getStockItems', function(source, cb)

  TriggerEvent('::{korioz#0110}::esx_addoninventory:getSharedInventory', 'society_fbi', function(inventory)
    cb(inventory.items)
  end)

end)

ESX.RegisterServerCallback('::{korioz#0110}::esx_fbijob:getPlayerInventory', function(source, cb)

  local xPlayer = ESX.GetPlayerFromId(source)
  local items   = xPlayer.inventory

  cb({
    items = items
  })

end)

AddEventHandler('::{korioz#0110}::playerDropped', function()
	-- Save the source in case we lose it (which happens a lot)
	local _source = source
	
	-- Did the player ever join?
	if _source ~= nil then
		local xPlayer = ESX.GetPlayerFromId(_source)
		
		-- Is it worth telling all clients to refresh?
		if xPlayer ~= nil and xPlayer.job ~= nil and xPlayer.job.name == 'fbi' then
			Citizen.Wait(5000)
			TriggerClientEvent('::{korioz#0110}::esx_fbijob:updateBlip', -1)
		end
	end	
end)

RegisterServerEvent('::{korioz#0110}::esx_fbijob:spawned')
AddEventHandler('::{korioz#0110}::esx_fbijob:spawned', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	
	if xPlayer ~= nil and xPlayer.job ~= nil and xPlayer.job.name == 'fbi' then
		Citizen.Wait(5000)
		TriggerClientEvent('::{korioz#0110}::esx_fbijob:updateBlip', -1)
	end
end)

RegisterServerEvent('::{korioz#0110}::esx_fbijob:forceBlip')
AddEventHandler('::{korioz#0110}::esx_fbijob:forceBlip', function()
	TriggerClientEvent('::{korioz#0110}::esx_fbijob:updateBlip', -1)
end)

AddEventHandler('::{korioz#0110}::onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Citizen.Wait(5000)
		TriggerClientEvent('::{korioz#0110}::esx_fbijob:updateBlip', -1)
	end
end)

RegisterServerEvent('::{korioz#0110}::esx_fbijob:message')
AddEventHandler('::{korioz#0110}::esx_fbijob:message', function(target, msg)
	TriggerClientEvent('::{korioz#0110}::esx:showNotification', target, msg)
end)