# 各種ライブラリの呼出し
require 'selenium-webdriver'
require "open-uri"
require "csv" 
require "nokogiri" 
require "./method.rb"

# ブラウザをChrome指定、selenium-webdriverをヘッドレスで起動
# heroku
caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {binary: "/app/.apt/usr/bin/google-chrome", args: ["--headless"]})
driver = Selenium::WebDriver.for :chrome, desired_capabilities: caps
wait = Selenium::WebDriver::Wait.new(:timeout => 10) 

# Yahooショッピングへアクセス
puts "商品検索後のURLを入力してください"
url = gets.chomp
driver.get(url)
# wait.until {driver.find_element(name:"p").displayed?}
# element = driver.find_element(name:"p")

# 検索ワードの入力
# puts "検索したい商品名を入力してください"
# search_word = gets.chomp
# element.send_keys(search_word, :enter)

# 検索商品数の入力
puts "検索したいページ数（30商品/ページ）を入力してください"
input = gets.chomp
pages = input.to_i - 1
pages.times do
  driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
  sleep(3)
end
wait.until {driver.find_element(:xpath, "//ul[@class = 'LoopList LoopList--grid4']/li//a[@class = '_2EW-04-9Eayr']").displayed?}
results = driver.find_elements(:xpath, "//ul[@class = 'LoopList LoopList--grid4']/li//a[@class = '_2EW-04-9Eayr']")

# 情報取得
i = 1
urls = results.map {|result| result.attribute('href') }
urls.each do |url|
  puts "*************#{i}個目の商品情報を取得中*************"
  if url.include?("paypaymall") # Paypayモールの場合
    driver.get(url)
    title = driver.find_element(:xpath, "//div[@id='itm_ov']/div[1]/div/h1").text
    sleep(1)
  # 商品ページ内全てのレビューを表示
    begin  
      driver.find_element(:xpath, "//*[@id='review']/div[1]/a").click
      driver.find_element(:xpath, "//*[@id='shpMain']/div[2]/div[1]/div/div[2]/div/div[1]/div/ul/li[4]").click
      sleep(1)
      while driver.find_element(:xpath, "//*[@id='more_button']/p/button").displayed?
          driver.find_element(:xpath, "//*[@id='more_button']/p/button").click
          sleep(1)
      end
    rescue => e
      puts "レビューがありません"
    end
    # 情報取得
    info = []
    info.push(title)
    elements = driver.find_elements(:xpath, "//*[@id='shpMain']/div[2]/div[1]/div/div[2]/div/ul/li/div/p[@class = 'elItemDate']")
    elements.each do |element|
      info.push(element.text)
      # puts element.text
    end
  else # Yahooショッピングの場合
    driver.get(url)
    title = driver.find_element(:xpath, "//div[@id='shpMain']//p[@class = 'elName']").text
    sleep(1)
    # 商品ページ内全てのレビューを表示
    begin
      driver.find_element(:xpath, "//*[@id='itmrvwfl']/div[2]/div[4]/ul/li").click
      driver.find_element(:xpath, "//*[@id='shpMain']/div[2]/div[1]/div/div[2]/div/div[1]/div/ul/li[4]").click
      sleep(1)
      while driver.find_element(:xpath, "//*[@id='more_button']/p/button").displayed?
          driver.find_element(:xpath, "//*[@id='more_button']/p/button").click
          sleep(1)
      end
    rescue => e
      puts "レビューがありません"
    end
    # 情報取得
    info = []
    info.push(title)
    elements = driver.find_elements(:xpath, "//*[@id='shpMain']/div[2]/div[1]/div/div[2]/div/ul/li/div/p[@class = 'elItemDate']")
    elements.each do |element|
      info.push(element.text)
      # puts element.text
    end
  end
  CSV.open("research.csv","a", :encoding => "SJIS") do |csv|
          csv << info
  end
  i = i + 1
  # 待機時間
  sleep(4)
end

driver.quit