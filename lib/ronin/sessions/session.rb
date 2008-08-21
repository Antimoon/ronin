#
#--
# Ronin - A ruby development platform designed for information security
# and data exploration tasks.
#
# Copyright (c) 2006-2008 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#++
#

require 'ronin/parameters'

module Ronin
  module Sessions
    module Session
      #
      # Includes Parameters and runs the _block_ in the specified
      # _base_class_.
      #
      def Session.setup_class(base_class,&block)
        base_class.module_eval { include Parameters }
        base_class.module_eval(&block)

        return base_class
      end

      #
      # Extends Parameters and runs the specified _block_ in the specified
      # _obj_.
      #
      def Session.setup_object(obj,&block)
        obj.extend(Parameters)
        obj.instance_eval(&block)

        return obj
      end
    end
  end
end
