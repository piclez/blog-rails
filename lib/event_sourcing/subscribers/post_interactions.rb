require 'browser'

module EventSourcing
  module Subscribers
    class PostInteractions
      def call(event)
        initialize_daily_visit(event)

        find_or_initialize_counter(event).tap do |visitor_post_counter|
          visitor_post_counter
            .update(views_count: visitor_post_counter.views_count + 1)
        end
      end

      private

      def find_or_initialize_counter(event)
        ::Analytics::VisitorPostDailyCounter
          .find_or_initialize_by(
            post_id: event.data[:post_id],
            day: Date.today,
            visitor_ip: event.metadata[:request_ip]
          )
      end

      def initialize_daily_visit(event)
        visit = ::Analytics::UniqueDailyVisit.find_or_initialize_by(
          visitor_ip: event.metadata[:request_ip],
          user_agent: event.data[:user_agent],
          referer: event.data[:referer],
          day: Date.today
        )

        add_visit_data(event, visit)
      end

      def add_visit_data(event, visit)
        return if visit.persisted?

        visit.update(
          country: country(event.metadata[:request_ip])['country'],
          browser: browser(event.data[:user_agent]).name,
          device:  device(event.data[:user_agent]),
        )
      end

      def browser(user_agent)
        @find_browser ||=
          Browser.new(user_agent, accept_language: 'en-us')
      end

      def device(user_agent)
        browser = browser(user_agent)
        return 'mobile' if browser.device.mobile?
        return 'tablet' if browser.device.tablet?

        'desktop'
      end

      def country(request_ip)
        url = URI.parse("http://ip-api.com/json/#{request_ip}")
        request = Net::HTTP::Get.new(url.to_s)
        response = Net::HTTP.start(url.host, url.port) { |http| http.request(request) }
        JSON.parse(response.body)
      rescue Net::OpenTimeout
        {}
      end
    end
  end
end
