describe EventSourcing::Publishers::HomePageViewed do
  it 'calls PublishService with the right payload' do
    HomeRequest = Struct.new(:original_url, :remote_ip, :user_agent, :referer)

    request = HomeRequest.new("http://test.host/",
                              '',
                              'Rails Testing',
                              'www.twitter.com')

    expected_payload = {
      page: "http://test.host/",
      visitor_ip: '',
      user_agent: 'Rails Testing',
      referer: 'www.twitter.com',
      tag_filter: 'performance'
    }

    expect(::EventSourcing::PublishProxy).to receive(:call)
      .with('home_page_viewed', expected_payload, 'performance')

    described_class.call(request, 'performance')

  end
end
