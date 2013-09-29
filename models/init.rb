DataMapper.setup(:default, ENV['CLEARDB_DATABASE_URL'] || 'mysql://root@localhost/quaker')
DataMapper.auto_upgrade!

require_relative 'place'