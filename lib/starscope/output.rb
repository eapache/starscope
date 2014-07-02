require 'ruby-progressbar'

class StarScope::Output

  PBAR_FORMAT = '%t: %c/%C %E ||%b>%i||'

  def initialize(level)
    @level = level
    @pbar = nil
  end

  def new_pbar(title, num_items)
    if @level != :quiet
      @pbar = ProgressBar.create(:title => title, :total => num_items,
                                :format => PBAR_FORMAT, :length => 80)
    end
  end

  def inc_pbar
    @pbar.increment if @pbar
  end

  def finish_pbar
    @pbar.finish if @pbar
    @pbar = nil
  end

  def log(msg)
    return if @level != :verbose

    if @pbar
      @pbar.log(msg)
    else
      puts msg
    end
  end

end
