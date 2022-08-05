require_dependency 'optimized_image'

OptimizedImage.class_eval do
  def self.resize_instructions(from, to, dimensions, opts = {})
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

    # -fuzz 4% -define trim:percent-background=0% -trim +repage -format jpg img.jpg

    if SiteSetting.topic_list_enable_thumbnail_black_border_elimination
      instructions.concat(%W{
        -fuzz 4%
        -define trim:percent-background=0%
        -trim
        +repage
      })
    end

    # NOTE: ORDER is important!
    instructions.concat(%W{
      -auto-orient
      -gravity center
      -background transparent
      -#{thumbnail_or_resize} #{dimensions}^
      -extent #{dimensions}
      -interpolate catrom
      -unsharp 2x0.5+0.7+0
      -interlace none
      -profile #{File.join(Rails.root, 'vendor', 'data', 'RT_sRGB.icm')}
      #{to}
    })
  end
end
