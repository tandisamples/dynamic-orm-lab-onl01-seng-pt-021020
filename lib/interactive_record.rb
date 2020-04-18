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

  #This is a method that grabs the table name we want to query. It takes the name of the class, referenced by the self keyword, turns it into a string with #to_s, downcases (or "un-capitalizes") that string and then "pluralizes" it, or makes it plural. The  #pluralize method is provided to us by the active_support/inflector code library, required at the top of lib/song.rb.

# Below is a method that grabs us those column names. Here we write a SQL statement using the pragma keyword and the #table_name method (to access the name of the table we are querying). We iterate over the resulting array of hashes to collect just the name of each column. We call #compact on that just to be safe and get rid of any nil values that may end up in our collection.


  def self.column_names
    DB[:conn].results_as_hash = true 
    ##results_as_hash method, available to use from the SQLite3-Ruby gem. This method says: when a SELECT statement is executed, don't return a database row as an array, return it as a hash with the column names as keys.

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end 
    column_names.compact
  end 

  #We already have .table_name to give us the table associated to a given class. BUT, #save is an instance method. Inside a #save method, self refers to an instance of the class, not the class itself. So to use a class methof inside an instance method, we need to say self.class.some_class_method.
  #To access the table name we want to INSERT into from inside the #save method, we can use the following:

  def table_name_for_insert
    self.class.table_name
  end 

  #Now we need to abstractly grab the column names. We already have a method called .column_names. But we need to control for the id, since Ruby assigns it nil before inserting into the table. When we save the Ruby object, it should exclude the id. Therefore, we need to remove "id" from the array of column names returned from the method call above:


  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    #
  end 

  #We already know that the names of that attr_accessor methods were derived from the column names of the table associated to our class. Those column names are stored in the #column_names class method.
  #If only there was some way to invoke those methods, without naming them explicitly, and capture their return values...
  #In fact, we already know how to programmatically invoke a method, without knowing the exact name of the method, using the #send method.
  #Let's iterate over the column names stored in #column_names and use the #send method with each individual column name to invoke the method by that same name and capture the return value:

  def values_for_insert
    values = []
    self.class.column_names.each do |column_name|
      values << "'#{send(column_name)}'" unless send(column_name).nil?
    end 
    #The above code, however, will result in a values array. We need comma separated values for our SQL statement. Let's join this array into a string:
    values.join(", ")
  end 

  def save
    #save the student to the database 
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)

    #("INSERT INTO students (name, grade) VALUES (?, ?)", "johnny", 9)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end 

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end 

  def self.find_by(attribute)
    column_name = attribute.keys[0].to_s
    value_name = attribute.values[0]
    #binding.pry

    sql = "SELECT * FROM #{table_name} WHERE #{column_name} = (?)"
    DB[:conn].execute(sql, value_name)
  end 
  
  
  
  
  
   
end