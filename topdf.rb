#!/usr/bin/jruby
# encoding: utf-8
# -*- coding: utf-8 -*-

require 'prawn'
module Prawn
  module Core
      def self.utf8_to_utf16(str)
        str
      end
  end
end
#File.delete 'test.pdf'
doc = Prawn::Document.new(:page_size => 'A4')

sorted = Dir['./pages/*.png'].slice 0, 10

sorted.each do |file|
doc.image file, :position => :center, :vposition => :center, :fit => [ 800, 900 ]
doc.start_new_page  
end
doc.render_file "test.pdf"
