json.message @message if @message

json.addon do
  json.partial! 'addon', addon: @addon
end
