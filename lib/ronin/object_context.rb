#
#--
# Ronin - A Ruby platform designed for information security and data
# exploration tasks.
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

require 'ronin/exceptions/unknown_object_context'
require 'ronin/exceptions/object_context_not_found'
require 'ronin/extensions/meta'
require 'ronin/context'

require 'dm-core'

module Ronin
  module ObjectContext
    include DataMapper::Types

    def self.included(base)
      base.class_eval do
        include Model
        include Context

        metaclass_def(:object_contextify) do |name|
          ObjectContext.object_contexts[name] = self

          contextify name

          # The Path to the object context
          property :object_path, String, :key => true

          # The modification timestamp of the object context
          property :object_timestamp, EpochTime

          meta_def(:load_object) do |path,*args|
            ObjectContext.load_object(context_name,path,*args)
          end

          meta_def(:cache) do |path,*args|
            load_object(path,*args).cache
          end

          meta_def(:mirror) do |path,*args|
            path = File.expand_path(path)
            existing_obj = first(:object_path => path)

            if existing_obj
              return existing_obj.mirror
            else
              return cache(path,*args)
            end
          end

          meta_def(:search) do |*attribs|
            all(*attribs).map { |obj| obj.object }
          end

          class_def(:object) do
            self.class.load_object(self.object_path)
          end

          class_def(:missing?) do
            if self.object_path
              return !(File.file?(self.object_path))
            end

            return false
          end

          class_def(:stale?) do
            if self.object_timestamp
              return File.mtime(self.object_path) > self.object_timestamp
            end

            return false
          end

          class_def(:cache) do
            if self.object_path
              self.object_timestamp = File.mtime(self.object_path)
              return save
            end

            return false
          end

          class_def(:mirror) do
            if self.object_path
              unless File.file?(self.object_path)
                return destroy
              else
                if (!(dirty?) && stale?)
                  destroy
                  return object.cache
                end
              end
            end

            return false
          end

          # define Repo-level object loader method
          Ronin.module_eval %{
            def ronin_load_#{name}(path,*args,&block)
              new_obj = #{self}.load_object(path,*args)
              
              block.call(new_obj) if block
              return new_obj
            end
          }
        end
      end
    end

    #
    # Returns the Hash of all defined object-contexts.
    #
    def ObjectContext.object_contexts
      @@ronin_object_contexts ||= {}
    end

    #
    # Returns +true+ if there is an object-context defined with the
    # specified _name_, returns +false+ otherwise.
    #
    def ObjectContext.is_object_context?(name)
      ObjectContext.object_contexts.has_key?(name.to_sym)
    end

    #
    # Loads the object context of the specified _name_ and from the
    # specified _path_ with the given _args_. If no object contexts were
    # defined with the specified _name_, an UnknownObjectContext
    # exception will be raised.
    #
    #   ObjectContext.load_object(:note,'/path/to/my_notes.rb') # => Note
    #
    def ObjectContext.load_object(name,path,*args,&block)
      name = name.to_sym

      unless ObjectContext.is_object_context?(name)
        raise(UnknownObjectContext,"unknown object context '#{name}'",caller)
      end

      path = File.expand_path(path)

      unless File.file?(path)
        raise(ObjectContextNotFound,"object context #{path.dump} does not exist",caller)
      end

      new_obj = Context.load_context(name,path,*args)
      new_obj.object_path = path

      block.call(new_obj) if block
      return new_obj
    end

    #
    # Loads all object contexts from the specified _path_ returning an
    # +Array+ of loaded object contexts. If a _block_ is given, it will
    # be passed each loaded object context.
    #
    #   Context.load_contexts('/path/to/misc_contexts.rb') # => [...]
    #
    def ObjectContext.load_objects(path,&block)
      path = File.expand_path(path)

      unless File.file?(path)
        raise(ObjectContextNotFound,"object context #{path.dump} does not exist",caller)
      end

      return Context.load_contexts(path) do |new_obj|
        new_obj.object_path = path

        block.call(new_obj) if block
      end
    end

    #
    # Cache all objects loaded from the specified _path_.
    #
    def ObjectContext.cache_objects(path)
      ObjectContext.load_objects(path).each do |obj|
        obj.cache
      end
    end

    #
    # Cache all objects loaded from the paths within the specified
    # _directory_.
    #
    def ObjectContext.cache_objects_in(directory)
      directory = File.expand_path(directory)
      paths = Dir[File.join(directory,'**','*.rb')]

      paths.each do |path|
        ObjectContext.load_objects(path).each do |obj|
          obj.cache
        end
      end

      return nil
    end

    #
    # Mirror all objects that were previously cached from paths within
    # the specified _directory_. Also cache objects which have yet to
    # be cached.
    #
    def ObjectContext.mirror_objects_in(directory)
      directory = File.expand_path(directory)
      paths = Dir[File.join(directory,'**','*.rb')]

      ObjectContext.object_contexts.each_value do |base|
        objects = base.all(:object_path.like => "#{directory}%")
        paths -= objects.map { |obj| obj.object_path }

        objects.each { |obj| obj.mirror }
      end

      paths.each do |path|
        ObjectContext.cache_objects(path)
      end

      return nil
    end

    #
    # Deletes all cached objects that existed in the specified _directory_.
    #
    def ObjectContext.expunge_objects_from(directory)
      directory = File.expand_path(directory)

      ObjectContext.object_contexts.each_value do |base|
        base.all(:object_path.like => "#{directory}%").destroy!
      end

      return nil
    end
  end
end
