require 'csv'
require 'set'
require 'date'
require 'time'

# processing data from Stanford Open Policing Project data:
# https://openpolicing.stanford.edu/data/


def outcome_types(filename)
    result = Set.new
    # Note that:
    # %i[numeric date] == [:numeric, :date]
    CSV.foreach(filename, headers: true, converters: %i[numeric date]) do |row|
        result << row['outcome']
    end
    return result
end


def outcome_types2(filename)
    # uses inject in a clever way!
    result = CSV.foreach(filename, headers: true, converters: %i[numeric date]).inject(Set.new) do |result, row|
        result << row['outcome']
    end
    return result
end

def outcome_types3(filename)
    # can just return the result of the inject() call
    return CSV.foreach(filename, headers: true, converters: %i[numeric date]).inject(Set.new) do |result, row|
        result << row['outcome']
    end
end


def any_type_set(filename, key)
    return CSV.foreach(filename, headers: true, converters: %i[numeric date]).inject(Set.new) do |result, row|
        result << row[key]
    end
end


def day_of_week(filename)
    result = Hash.new(0)
    CSV.foreach(filename, headers: true, converters: %i[numeric date]) do |row|
        date = row['date']
        result[date.cwday] += 1
    end
    return result
end


def any_type_hash(filename, key)
    # key is the name of any column header for a row
    result = Hash.new(0)
    CSV.foreach(filename, headers: true, converters: %i[numeric date]) do |row|
        result[row[key]] += 1
    end
    return result
end


def cwday(date)
    return date.cwday
end


def hour(time)
    return time.split(':')[0].to_i
end


def any_type_hash2(filename, key, func=nil)
    # func is a function that does more processing on a column value
    # so for example, we may want to convert a time like "19:30:56" to just 19
    # or get the day of the week for a date like "2017-03-12"
    result = Hash.new(0)
    CSV.foreach(filename, headers: true, converters: %i[numeric date]) do |row|
        new_key = row[key]
        if func != nil
            new_key = func.call(new_key)
        end
        result[new_key] += 1
    end
    return result
end


def any_type_hash3(filename, key, func=nil)
    # Using inject() is tricky with a Hash
    return CSV.foreach(filename, headers: true, converters: %i[numeric date]).inject(Hash.new(0)) do |result, row|
        new_key = row[key]
        if func != nil
            new_key = func.call(new_key)
        end
        result[new_key] += 1
        # THIS LINE IS NECESSARY! inject() needs a return value after processing
        # each row to assign to the next version of result
        result
    end
end


def parse_all(filename)
    outcomes = Hash.new(0)
    days = Hash.new(0)
    hours = Hash.new(0)
    CSV.foreach(filename, headers: true, converters: %i[numeric date]) do |row|
        outcomes[row['outcome']] += 1
        days[row['date'].cwday] += 1
        hours[hour(row['time'])] += 1
    end
    puts outcomes
    puts days
    puts hours
end

def getPercentRace(file, key)
    h = any_type_hash(file, key)
    p h
    total = h.values.inject(0, :+)
    p total
    h.each_with_object({}) {|(k, v), h| h[k] = "#{(v * 100.0/total).round(4)}%"}
end

def getPercentGender(file, key)
    h = any_type_hash(file, key)
    p h
    total = h.values.inject(0, :+)
    p total
    h.each_with_object({}) {|(k, v), h| h[k] = "#{(v * 100.0/total).round(4)}%"}
end

def getMinMax(file)
    zip_array = []
    CSV.foreach(file, headers: true) do |row| 
        zip_array << row['subject_age']
    end
    # gets sum
    s = (zip_array.map{ |x| x[/\d+/].to_i }).sum
    # gets size
    n = (zip_array.map{ |x| x[/\d+/].to_i }).size
    # gets average
    p s/n
    # max
    p zip_array.max_by { |x| x[/\d+/].to_i }
    # min
    p zip_array.min
    # median
    p mid =n / 2
    sorted = (zip_array.map{ |x| x[/\d+/].to_i }).sort
    n.odd? ? sorted[mid] : 0.5 * (sorted[mid] + sorted[mid - 1])
    
end

def illegal_drivers(filename, key)
    zip_array = []
    CSV.foreach(filename, headers: true) do |row| 
        val = row['subject_age'].to_i
        if val < 16
            zip_array << row['subject_sex']
        end
    end
    h = Hash.new(0)
    # counts the occurrence of each value
    zip_array.each{|x| h[x] += 1}
    # rotal num of array
    total = h.values.inject(0, :+)
    # gets percent for values
    h.each_with_object({}) {|(k, v), h| h[k] = "#{(v * 100.0/total).round(2)}%"}
end

def violation_gender(filename)
    zip_array = []
    CSV.foreach(filename, headers: true) do |row| 
        if  row['violation'] != "NA"
            zip_array << row['subject_sex']
        end
    end
    h = Hash.new(0)
    # counts the occurrence of each value
    zip_array.each{|x| h[x] += 1}
    # rotal num of array
    total = h.values.inject(0, :+)
    # gets percent for values
    h.each_with_object({}) {|(k, v), h| h[k] = "#{(v * 100.0/total).round(2)}%"}
end

def crime_hour(filename)
    h = Hash.new(0)
    CSV.foreach(filename, headers: true) do |row| 
        if row["violation"] != "NA"
            hour = row['time'].partition(":").first
            if !hour.include?(hour) 
                h[hour] = 0
            end
            h[hour] += 1
        end
    end
    # total num of array
    total = h.values.inject(0, :+)
    # gets percent for values
    h = h.each_with_object({}) {|(k, v), h| h[k] = "#{(v * 100.0/total).round(2)}%"}
    h.max_by{|k,v| v}
end




if __FILE__ == $0
    # az = 'az_mesa_2020_04_01.csv'
    # azshort = 'az_mesa_short.csv'
    # vt = 'vt_burlington_2020_04_01.csv'
    # vt = 'vt_burlington_short.csv'
    # wy = 'wy_statewide_2020_04_01.csv'
    ly = 'loui.csv'
    ow = 'owen.csv'
    
    #p outcome_types(ly)
    # p outcome_types(ow)
    #p outcome_types2(vt)
    #p outcome_types3(vt)
    #p any_type_set(vt, 'outcome')
    #  p any_type_set(ly, 'raw_persons_race')
    #  p any_type_set(ly, 'subject_race')
    #  p any_type_set(ow, 'raw_race')
    #  p any_type_set(ow, 'subject_race')
    
    #p day_of_week(vt) 
    #p day_of_week(vt).sort_by(&:first).map(&:last)
    #  p any_type_hash(ow, 'subject_race')
    # p any_type_hash(ow, 'subject_race')
    # p getPercentRace(ly)
# p getPercentRace(ow)
    #p any_type_hash2(ow, 'date', method(:cwday)).sort_by(&:first).map(&:last)
    #p any_type_hash2(vt, 'outcome')
    #p any_type_hash2(vt, 'violation')
    #p any_type_hash2(vt, 'time', method(:hour)).sort_by(&:first).map(&:last)
    # p getPercentGender(ly, 'subject_race')
    # p getPercentGender(ow, 'subject_sex')
    #parse_all(vt)
    # p getMinMax(ow)
    #  p getMinMax(ow)
    #  p illegal_drivers(ly, 'subject_age')
    #  p illegal_drivers(ow, 'subject_age')
    # p getPercentGender(ow, 'violation')
    # p officer_driver(ow)
    # p violation_gender(ly)
    # p violation_gender(ow)
    p crime_hour(ly)
    p crime_hour(ow)
end