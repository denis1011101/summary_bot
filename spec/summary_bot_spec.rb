# frozen_string_literal: true

require "spec_helper"

describe Summarybot::Parser do
  describe ".air" do
    it "returns a string with the scale name, air status, conventional value and units and url" do
      url = 'https://www.iqair.com/ru/russia/sverdlovsk/yekaterinburg'
      result = Summarybot::Parser.air
      expect_result = /Индекс AQI в реальном времени: .+, \d+\* \(AQI США\)\n#{Regexp.escape(url)}/
      expect(result).to match(expect_result)
    end
  end
end

describe Summarybot::TelegramListener do
  describe ".listen" do
    context "when the last message was sent less than 40 seconds ago and matches 'air'" do
      it "returns the text of the last message", :skip => "TODO: clarify the logic" do
        allow(Faraday).to receive(:get).and_return(
          double(body: '{"result":[{"message":{"date":' + (Time.now.to_i - 39).to_s + ',"text":"air"}}]}')
        )
        expect(Summarybot::TelegramListener.listen).to eq("air")
      end
    end

    context "when the last message was sent more than 40 seconds ago" do
      it "returns nil" do
        allow(Faraday).to receive(:get).and_return(
          double(body: '{"result":[{"message":{"date":' + (Time.now.to_i - 41).to_s + ',"text":"air"}}]}')
        )
        expect(Summarybot::TelegramListener.listen).to be_nil
      end
    end

    context "when the last message does not match 'air'" do
      it "returns nil" do
        allow(Faraday).to receive(:get).and_return(
          double(body: '{"result":[{"message":{"date":' + (Time.now.to_i - 39).to_s + ',"text":"hello"}}]}')
        )
        expect(Summarybot::TelegramListener.listen).to be_nil
      end
    end
  end
end
