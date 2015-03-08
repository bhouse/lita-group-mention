module Lita
  # Lita Handler module
  module Handlers
    # GroupMention handler class
    class GroupMention < Handler
      route(/@(\w+)+/, :group_mention)
      route(
        /^group\s+mention\s+add\s+@?(?<user>\w+)\s+to\s+@?(?<group>\w+)/,
        :add_member,
        command: true,
        help: {
          t('help.add_user_key') => t('help.add_user_value')
        }
      )
      route(
        /^group\s+mention\s+remove\s+@?(?<user>\w+)\s+from\s+@?(?<group>\w+)/,
        :remove_member,
        command: true,
        help: {
          t('help.remove_user_key') => t('help.remove_user_value')
        }
      )
      route(
        /^group\s+mention\s+remove\s+group\s+@?(?<group>\w+)/,
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
        /^group\s+mention\s+show\s+group\s+@?(?<group>\w+)/,
        :show_group,
        command: true,
        help: {
          t('help.show_group_key') => t('help.show_group_value')
        }
      )
      route(
        /^group\s+mention\s+show\s+user\s+@?(?<user>\w+)/,
        :show_user,
        command: true,
        help: {
          t('help.show_user_key') => t('help.show_user_value')
        }
      )

      def group_mention(response) # rubocop:disable AbcSize
        return if response.message.body =~ /group\s+mention/
        groups = response.matches.flatten

        groups.each do |g|
          groups.delete(g) unless redis_groups.keys.include?(g)
        end
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
