#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'prawn'

doc = Prawn::Document.new(:page_size => 'A4')

sorted = Dir['./pages/*.png'].sort { |a,b|
  ma = a.match('(PR|PP|PA)([0-9]+)')
  mb = b.match('(PR|PP|PA)([0-9]+)')
  if ma[1] == mb[1]
  else
    if ma[1] == 'PP'
      return -1
    else
      if mb[1] == 'PP'
        return 1
      else
      end
  end
}

sorted.each do |file|
doc.image file, :position => :center, :vposition => :center  
doc.start_new_page  
end
doc.render_file "test.pdf"
