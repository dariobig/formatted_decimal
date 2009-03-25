# This module extends a model's decimal column with a virtual attributes to address Rails lack of 
# internationalization support of form helpers. This modules provides a setter and a getter method
# that format numbers according to the current app's locale (google "I18n.locale" for more info).  
#
# Usage:
#
# YourModel < < ActiveRecord::Base
#   include FormattedDecimal
#   formatted_decimal :total, :sub_total
#   ...
#
# Then in your views use the formatted_total and formatted_sub_total attributes instead:
#
# <%= text_field :invoice, :formatted_total, :size => 15 %>
# 
# Expects the locale file (app/config/locale/it.yml) to define a number format
# it:
#   number:
#     format:
#       separator: ","
#       delimiter: "'"
#       precision: 2

module FormattedDecimal
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    # Define a new class method that adds the getter and setter methods.
    def formatted_decimal(*args)
      args.is_a?(Array) ? symbols = args : symbols = [args]
      
      symbols.each do |symbol|
        # getter
        method = "formatted_#{symbol.to_s}"
        self.send(:define_method, method) do 
          formatNum(self.send(symbol))
        end

        # setter
        self.send(:define_method, method + '=') do |val|
          self.send("#{symbol}=", parseNum(val))
        end
      end    
    end
  end

  protected
  # Returns the default number format from the current I18n locale.
  def getNumFormat
    begin 
      I18n.translate(:'number.format', :locale => I18n.locale, :raise => true) 
    rescue 
      { :precision => 3, :separator => ".", :delimiter => "" }
    end
  end
  
  # Parses a formatted number into a BigDecimal.
  def parseNum(num)
    format = getNumFormat
    
    begin
      parts = num.to_s.split(format[:separator])
      parts[0].gsub!(format[:delimiter], '')
      parts[1] = parts[1][0,format[:precision]] if format[:precision]
      parts.join('.').to_d
    rescue
      num
    end
  end
  
  # Prints a number to a string, formatted using the correct locale.
  def formatNum(num)
    format = getNumFormat
    
    begin
      parts = num.to_s.split('.')
      parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{format[:delimiter]}")
      parts[1] = parts[1][0,format[:precision]] if format[:precision]
      parts.join(format[:separator])
    rescue
      num
    end
  end
end