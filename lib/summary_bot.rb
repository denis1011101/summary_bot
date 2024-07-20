# frozen_string_literal: true

require_relative "summary_bot/version"
  require "nokogiri"
  require "faraday"

ENV["TZ"] = "Asia/Yekaterinburg"
TOKEN = ENV["TOKEN"]
CHAT_ID = ENV["CHAT_ID"]

# Basic module for parsing and sending notifications in telegram bot when find keywords
module Summarybot
  class Error < StandardError; end

  # For parsing information from sites with help nokogiri and faraday
  class Parser
    def self.fetch_document(url)
      Nokogiri::HTML(Faraday.get(url).body)
    end

    def self.extract_scale_name(doc)
      doc.xpath('//span[@class="aqi-status__label"]').text.strip
    end

    def self.extract_air_status(doc)
      doc.xpath('//span[@class="aqi-status__text"]').text.strip
    end

    def self.extract_conventional_units(doc)
      doc.xpath('//p[@class="aqi-value__unit"]').text.strip
    end

    def self.extract_conventional_value(doc)
      doc.xpath('//p[@class="aqi-value__value"]').text.strip
    end

    def self.fetch_air_values
      @url = "https://www.iqair.com/ru/russia/sverdlovsk/yekaterinburg"
      doc = fetch_document(@url)
      @scale_name = extract_scale_name(doc)
      @air_status = extract_air_status(doc)
      @conventional_units = extract_conventional_units(doc)
      @conventional_value = extract_conventional_value(doc)
    end

    def self.air
      fetch_air_values
      "#{@scale_name}: #{@air_status}, #{@conventional_value} (#{@conventional_units})\n#{@url}"
    end

    def self.weather
      url                     = 'https://yandex.ru/pogoda/yekaterinburg'
    end
  end

  # For sending information to telegram chat
  class TelegramSender
    require "faraday"

    URL = "https://api.telegram.org/bot#{TOKEN}/sendMessage".freeze

    def self.send
      Faraday.post(URL, { chat_id: CHAT_ID, text: Parser.air })
    end
  end

  # For listening telegram chat
  class TelegramListener
    require "faraday"
    require "json"

    AWAIT_MESSAGE_TIME = Time.now.to_i - 60
    URL = "https://api.telegram.org/bot#{TOKEN}/getUpdates".freeze

    def self.listen
      response = Faraday.get(URL)
      body = response.body
      return nil if body.nil? || body.empty?

      result = JSON.parse(body)["result"]
      return nil if result.nil? || result.empty?

      message = result[-1]["message"]
      return nil if message.nil? || message.empty?

      text_message = JSON.parse(response.body)["result"][-1]["message"]["text"] if
      JSON.parse(response.body)["result"][-1]["message"]["date"] > AWAIT_MESSAGE_TIME

      case text_message
      when "air?"
        TelegramSender.send
      when "when?"
        TelegramSender.send
      end
    end
  end

  # For running telegram bot
  class Bot
    def self.run
      TelegramListener.listen
    end
  end

  Bot.run
end
