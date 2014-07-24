json.array!(@orders) do |order|
  json.extract! order, :id, :placed_on, :packed_on, :delivered_on, :description, :status
  json.url order_url(order, format: :json)
end
