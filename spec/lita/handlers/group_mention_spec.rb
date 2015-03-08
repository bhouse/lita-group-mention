require 'spec_helper'

shared_examples 'commands' do
  before(:each) do
    redis_connection.flushdb
  end

  it 'adds a user to a group' do
    send_command("group mention add #{command_user} to #{command_group}")
    expect(replies.last).to eq("Added @#{chat_user} to #{chat_group}")
    expect(redis.smembers("group:#{chat_group}")).to include(chat_user)
    expect(redis.smembers("user:#{chat_user}")).to include(chat_group)
  end

  it 'removes a user from a group' do
    redis.sadd("group:#{chat_group}", chat_user)
    redis.sadd("user:#{chat_user}", chat_group)

    send_command("group mention remove #{command_user} from #{command_group}")

    expect(replies.last).to eq(
      "Removed @#{chat_user} from #{chat_group}"
    )
    expect(
      redis.smembers("group:#{chat_group}")
    ).not_to include(chat_user)
    expect(
      redis.smembers("user:#{chat_user}")
    ).not_to include(chat_group)
  end

  it 'removes a group' do
    redis.sadd("group:#{chat_group}", chat_user)
    redis.sadd("user:#{chat_user}", chat_group)
    redis.sadd("user:#{chat_user}", 'foo')

    send_command("group mention remove group #{command_group}")

    expect(replies.last).to eq("Removed the #{chat_group} group")
    expect(redis.smembers("user:#{chat_user}")).to eq(['foo'])
    expect(redis.smembers("group:#{chat_group}")).to be_empty
  end

  it 'shows all the groups' do
    redis.sadd("group:#{chat_group}", chat_user)

    send_command('group mention show groups')
    expect(replies.last).to eq("#{chat_group}: #{chat_user}")
  end

  it 'show that a group does not exist' do
    send_command('group mention show group baz')
    expect(replies.last).to eq('baz does not exist')
  end

  it 'shows a specific group' do
    redis.sadd("group:#{chat_group}", chat_user)

    send_command("group mention show group #{command_group}")
    expect(replies.last).to eq("#{chat_group}: #{chat_user}")
  end

  it 'shows the groups a user is a member of' do
    redis.sadd("user:#{chat_user}", chat_group)

    send_command("group mention show user #{command_user}")
    expect(replies.last).to eq("#{chat_user}: #{chat_group}")
  end
end

describe Lita::Handlers::GroupMention, lita_handler: true do
  before(:each) do
    redis_connection.flushdb
  end

  after do
    redis_connection.flushdb
  end

  let(:redis_namespace) { 'lita.test:handlers:group_mention' }
  let(:redis_connection) do
    Redis::Namespace.new(redis_namespace, redis: Redis.new)
  end

  context 'commands sent without @ mentions' do
    include_examples 'commands' do
      let(:redis) { redis_connection }
      let(:chat_user) { 'test_user1' }
      let(:chat_group) { 'test_group1' }
      let(:command_user) { chat_user }
      let(:command_group) { chat_group }
    end
  end

  context 'commands sent with @ mentions' do
    include_examples 'commands' do
      let(:redis) { redis_connection }
      let(:chat_user) { 'test_user1' }
      let(:chat_group) { 'test_group1' }
      let(:command_user) { '@' + chat_user }
      let(:command_group) { '@' + chat_group }
    end
  end

  context 'sending a message with a group mention' do
    it 'expands the group mention to mention a list of users' do
      redis_connection.sadd('group:group1', 'user1')
      redis_connection.sadd('group:group1', 'user2')

      send_message('Hello @group1')

      expect(replies.last).to eq('cc @user1, @user2')
    end
  end

  context 'sending a message with multiple group mentions' do
    it 'expands all groups and joins their members in the mention' do
      %w(10 11 12).each do |n|
        redis_connection.sadd('group:group1', "user#{n}")
      end
      redis_connection.sadd('group:group2', 'user20')
      redis_connection.sadd('group:group2', 'user21')
      redis_connection.sadd('group:group2', 'user10')

      send_message('Hello @group1 and @group2')

      expect(replies.last).to eq(
        'cc @user10, @user11, @user12, @user20, @user21'
      )
    end
  end
end
