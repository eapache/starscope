require 'ruby-progressbar'

class Starscope::Output
  PBAR_FORMAT = '%t: %c/%C %E ||%b>%i||'

  def initialize(level, out = STDOUT)
    @out = out
    @level = level
    @pbar = nil
  end

  def new_pbar(title, num_items)
    if @level != :quiet
      @pbar = ProgressBar.create(:title => title, :total => num_items,
                                 :format => PBAR_FORMAT, :length => 80,
                                 :out => @out)
    end
  end

  def inc_pbar
    @pbar.increment if @pbar
  end

  def finish_pbar
    @pbar.finish if @pbar
    @pbar = nil
  end

  def extra(msg)
    return unless @level == :verbose
    output(msg)
  end

  def normal(msg)
    return if @level == :quiet
    output(msg)
  end

  private

  def output(msg)
    if @pbar
      @pbar.log(msg)
    else
      @out.puts msg
    end
  end
end
