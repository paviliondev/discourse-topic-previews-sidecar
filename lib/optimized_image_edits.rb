require_dependency 'optimized_image'

# OptimizedImage.class_eval do

module OptimizedImmageExtension

  def optimize(operation, from, to, dimensions, opts = {})
    method_name = "#{operation}_instructions"

    pp"###########################  ###########################"
    pp method_name
    pp"###########################  ###########################"
    instructions = self.public_send(method_name.to_sym, from, to, dimensions, opts)
    pp"###########################  ###########################"
    pp instructions
    pp"###########################  ###########################"
    pp from
    pp"###########################  ###########################"
    pp to
    pp"###########################  ###########################"
    pp dimensions
    pp"###########################  ###########################"
    pp opts
    pp"###########################  ###########################"
    convert_with(instructions, to, opts)
  end


  # alias_method :old_resize_instructions, :resize_instructions

  def resize_instructions(from, to, dimensions, opts = {})
    if SiteSetting.topic_list_enable_thumbnail_black_border_elimination 
      dimensions = dimensions.split("x",2)[0]
    end

    ensure_safe_paths!(from, to)

    # note FROM my not be named correctly
    from = prepend_decoder!(from, to, opts)
    to = prepend_decoder!(to, to, opts)

    instructions = ['convert', "#{from}[0]"]

    if opts[:colors]
      instructions << "-colors" << opts[:colors].to_s
    end

    if opts[:quality]
      instructions << "-quality" << opts[:quality].to_s
    end

    # NOTE: ORIGINAL, ORDER is important!
    # instructions.concat(%W{
    #   -auto-orient
    #   -gravity center
    #   -background transparent
    #   -#{thumbnail_or_resize} #{dimensions}^
    #   -extent #{dimensions}
    #   -interpolate catrom
    #   -unsharp 2x0.5+0.7+0
    #   -interlace none
    #   -profile #{File.join(Rails.root, 'vendor', 'data', 'RT_sRGB.icm')}
    #   #{to}
    # })

    # ALGO -fuzz 4% -define trim:percent-background=0% -trim +repage -format jpg img.jpg

    # NOTE: ORDER is important!
    instructions.concat(%W{
      -auto-orient
      -gravity center
    })

    unless SiteSetting.topic_list_enable_thumbnail_black_border_elimination
      instructions.concat(%W{
        -background transparent
        -#{thumbnail_or_resize} #{dimensions}^
        -extent #{dimensions}
      })
    else
      instructions.concat(%W{
        -#{thumbnail_or_resize} #{dimensions.split("x",2)[0]}^
        -extent #{dimensions.split("x",2)[0]}
      })
    end
    
    instructions.concat(%W{
      -interpolate catrom
      -unsharp 2x0.5+0.7+0
      -interlace none
      -profile #{File.join(Rails.root, 'vendor', 'data', 'RT_sRGB.icm')}
    })

    if SiteSetting.topic_list_enable_thumbnail_black_border_elimination
      instructions.concat(%W{
        -fuzz 2%
        -define trim:percent-background=0%
        -trim
        +repage
      })
    end

    instructions.concat(%W{
      #{to}
    })
  end

  def self.crop_instructions(from, to, dimensions, opts = {})
    if SiteSetting.topic_list_enable_thumbnail_black_border_elimination 
      dimensions = dimensions.split("x",2)[0]
    end

    ensure_safe_paths!(from, to)

    from = prepend_decoder!(from, to, opts)
    to = prepend_decoder!(to, to, opts)

    instructions = ['convert', "#{from}[0]"]

    if SiteSetting.topic_list_enable_thumbnail_black_border_elimination
      instructions.concat(%W{
        -fuzz 2%
        -define trim:percent-background=0%
        -trim
        +repage
      })
    end

    instructions.concat(%W{
      -auto-orient
      -gravity north
      -background transparent
      -#{thumbnail_or_resize} #{dimensions}^
      -crop #{dimensions}+0+0
      -unsharp 2x0.5+0.7+0
      -interlace none
      -profile #{File.join(Rails.root, 'vendor', 'data', 'RT_sRGB.icm')}
    })

    if opts[:quality]
      instructions << "-quality" << opts[:quality].to_s
    end

    instructions << to
end

  def self.downsize_instructions(from, to, dimensions, opts = {})
    if SiteSetting.topic_list_enable_thumbnail_black_border_elimination 
      dimensions = dimensions.split("x",2)[0]
    end

    ensure_safe_paths!(from, to)

    from = prepend_decoder!(from, to, opts)
    to = prepend_decoder!(to, to, opts)

    instructions = ['convert', "#{from}[0]"]

    if SiteSetting.topic_list_enable_thumbnail_black_border_elimination
      instructions.concat(%W{
        -fuzz 2%
        -define trim:percent-background=0%
        -trim
        +repage
      })
    end

    instructions.concat(%W{
      -auto-orient
      -gravity center
      -background transparent
      -interlace none
      -resize #{dimensions}
      -profile #{File.join(Rails.root, 'vendor', 'data', 'RT_sRGB.icm')}
      #{to}
    })
  end
end
