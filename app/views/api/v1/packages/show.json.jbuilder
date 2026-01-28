json.message @message if @message

json.package do
  json.partial! 'package', package: @package
end
