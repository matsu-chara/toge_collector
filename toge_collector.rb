# frozen_string_literal: true

require 'slack'

# ARGV[0] = slack_token (required)
# ARGV[1] = url         (required)
# ARGV[2] = count       (optional)
def parse_arg
  url = ARGV[1]
  base_url = url.split('/')[0..-2].join('/')
  channel_name = url.split('/')[-2]
  timestamp = (url.split('/')[-1][1..-1]).to_f / 1_000_000
  count = ARGV[2].to_i || 1000
  {
    token: ARGV[0], base_url: base_url, channel_name: channel_name,
    oldest: timestamp, count: count
  }
end

arg = parse_arg
client = Slack::Client.new token: arg[:token]

channel_id = (client.channels_list(exclude_archived: 1)['channels'].find do |e|
  e['name'] == arg[:channel_name]
end)['id']

messages = (client.channels_history(
  channel: channel_id,
  oldest:  arg[:oldest],
  inclusive: 1,
  count:   [arg[:count], 1000].min
)['messages'].map do |m|
  { message: m['text'], timestamp: m['ts'].sub(/\./, '') }
end).reverse

# togelackは30件ずつのurlを要求するので、30件に１個だけ表示する
infos = (messages.select.with_index { |_, idx| idx % 30 == 0 }).map do |m|
  { message: m[:message], url: "#{arg[:base_url]}/p#{m[:timestamp]}" }
end

puts '===messages==='
messages.each_with_index do |e, idx|
  puts "#{idx / 30}-#{idx % 30} #{e[:message]}"
end
puts ''
puts '===urls==='
infos.each { |e| puts "\"#{e[:url]}\"" }
