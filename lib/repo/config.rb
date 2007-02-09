#
# Ronin - A decentralized repository for the storage and sharing of computer
# security advisories, exploits and payloads.
#
# Copyright (c) 2007 Hal Brodigan (postmodern at users.sourceforge.net)
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
#

require 'category'
require 'exceptions/repositorynotfound'

module Ronin
  module Repo

    # TODO: make this cross-platform later
    CONFIG_PATH = "/etc/ronin.conf"

    # Current operating configuration
    $current_config = nil

    class Config

      # Path of config file
      attr_reader :path

      # Hash of loaded repositories
      attr_reader :repos

      def initialize(path=CONFIG_PATH)
	@path = path
        @repos = {}
        # TODO: parse REPOS_CONFIG and create Hash of repositories.
      end

      def get_repository(repo)
	unless @repos[repo]
	  raise, RepositoryNotFound, "repository not listed in config file '#{self}'"
	end
      end

      def to_s
	return @path
      end

    end
  end
end
