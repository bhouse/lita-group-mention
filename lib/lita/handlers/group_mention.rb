module Lita
  # Lita Handler module
  module Handlers
    # GroupMention handler class
    class GroupMention < Handler # rubocop:disable Metrics/ClassLength
      # Preload mention groups into redis
      # configure format: {'group1' => ['member1', 'member2']}
      config :groups, type: Hash, default: nil

      route(/@([a-zA-Z0-9.\-_]+)+/, :group_mention)
      route(
        /^group\s+mention\s+add\s+@?(?<user>[a-zA-Z0-9.\-_]+)\s+to\s+@?(?<group>[a-zA-Z0-9.\-_]+)/,
        :add_member,
        command: true,
        help: {
          t('help.add_user_key') => t('help.add_user_value')
        }
      )
      route(
        /^group\s+mention\s+remove\s+@?(?<user>[a-zA-Z0-9.\-_]+)\s+from\s+@?(?<group>[a-zA-Z0-9.\-_]+)/,
        :remove_member,
        command: true,
        help: {
          t('help.remove_user_key') => t('help.remove_user_value')
        }
      )
      route(
        /^group\s+mention\s+remove\s+group\s+@?(?<group>[a-zA-Z0-9.\-_]+)/,
        :remove_group,
        command: true,
        help: {
          t('help.remove_group_key') => t('help.remove_group_value')
        }
      )
      route(
        /^group\s+mention\s+show\s+groups$/,
        :show_groups,
        command: true,
        help: {
          t('help.show_groups_key') => t('help.show_groups_value')
        }
      )
      route(
        /^group\s+mention\s+show\s+group\s+@?(?<group>[a-zA-Z0-9.\-_]+)/,
        :show_group,
        command: true,
        help: {
          t('help.show_group_key') => t('help.show_group_value')
        }
      )
      route(
        /^group\s+mention\s+show\s+user\s+@?(?<user>[a-zA-Z0-9.\-_]+)/,
        :show_user,
        command: true,
        help: {
          t('help.show_user_key') => t('help.show_user_value')
        }
      )

      on :loaded, :preload_groups

      def group_mention(response) # rubocop:disable AbcSize
        return if response.message.body =~ /group\s+mention/
        groups = response.matches.flatten
        groups.reject! { |g| !redis_groups.keys.include?(g) }
        return if groups.empty?

        response.reply(t('mention.cc') + union_members(groups))
      end

      def add_member(response)
        group = response.match_data['group']
        user = response.match_data['user']
        redis.sadd("user:#{user}", group)
        redis.sadd("group:#{group}", user)
        response.reply(t('add_member', user: user, group: group))
      end

      def remove_member(response)
        group = response.match_data['group']
        user = response.match_data['user']
        redis.srem("user:#{user}", group)
        redis.srem("group:#{group}", user)
        response.reply(t('remove_member', user: user, group: group))
      end

      def remove_group(response)
        group = response.match_data['group']
        members = redis.smembers("group:#{group}")
        members.each do |user|
          redis.srem("user:#{user}", group)
        end

        redis.del("group:#{group}")
        response.reply(t('remove_group', group: group))
      end

      def show_groups(response)
        group_list = []
        redis_groups.each do |group, members|
          group_list << "#{group}: #{members.join(', ')}"
        end
        response.reply(group_list.join("\n"))
      end

      def show_group(response)
        group = response.match_data['group']

        unless redis_groups.key?(group)
          response.reply(t('group_does_not_exist', group: group))
          return
        end

        members = redis_groups[group]
        formatted_group = "#{group}: #{members.join(', ')}"
        response.reply(formatted_group)
      end

      def show_user(response)
        user = response.match_data['user']
        response.reply("#{user}: #{get_user_memberships(user).join(', ')}")
      end

      def preload_groups(_)
        config.groups.each do |group, members|
          members.each do |member|
            log.info("Load group mention: user[#{member}] group[#{group}]")
            redis.sadd("user:#{member}", group)
            redis.sadd("group:#{group}", member)
          end
        end if config.groups.is_a?(Hash)
      end

      private

      def redis_groups
        @groups ||= {}
        redis.keys('group:*').each do |group|
          @groups[group.split(':')[-1]] = redis.smembers(group)
        end
        @groups
      end

      def get_user_memberships(user)
        redis.smembers("user:#{user}")
      end

      def union_members(groups)
        groups = groups.map { |g| "group:#{g}" }
        redis.sunion(groups).sort.map { |m| "@#{m}" }.join(', ')
      end
    end

    Lita.register_handler(GroupMention)
  end
end
