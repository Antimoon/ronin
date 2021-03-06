#
# Copyright (c) 2006-2012 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# This file is part of Ronin.
#
# Ronin is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ronin is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ronin.  If not, see <http://www.gnu.org/licenses/>.
#

require 'ronin/database'

require 'rspec'
require 'tempfile'

RSpec.configure do |spec|
  spec.before(:suite) do
    defaults = {
      :user     => 'ronin_test',
      :password => 'ronin_test',
      :database => 'ronin_test'
    }
    adapter  = ENV.fetch('ADAPTER','sqlite3')

    uri = case adapter
          when 'sqlite3', 'sqlite'
            {
              :adapter  => 'sqlite3',
              :database => Tempfile.new('ronin_database').path
            }
          else
            defaults.merge(:adapter => adapter)
          end

    # setup the database
    Ronin::Database.setup(uri)

    # auto-migrate any models defined in the specs
    DataMapper.finalize.auto_migrate!
  end
end
