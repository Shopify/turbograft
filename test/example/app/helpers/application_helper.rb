module ApplicationHelper

  def biased_color(offset_from_black)
    offset_from_black + rand(255 - offset_from_black)
  end
  def random_light_rgb
    "rgb(#{biased_color(150)}, #{biased_color(150)}, #{biased_color(150)});"
  end
end
