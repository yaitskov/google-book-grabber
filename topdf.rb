#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'prawn'


doc = Prawn::Document.new(:page_size => 'A4')
doc.font "Times-Roman", :size => 12
doc.text "hello world"
doc.start_new_page

doc.text "hello world"
doc.start_new_page

doc.text "hello world"
doc.start_new_page
doc.image 'PP1.png', :position => :center, :vposition => :center


doc.render_file "test.pdf"
