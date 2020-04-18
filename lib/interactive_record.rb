require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end 

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end 
  
  
  
  
  
  
   
end