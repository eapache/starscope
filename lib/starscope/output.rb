require 'ruby-progressbar'

class StarScope::Output

  PBAR_FORMAT = '%t: %c/%C %E ||%b>%i||'

  def initialize(progress, verbose)
    @progress = progress
    @verbose = verbose
    @pbar = nil
  end

  def new_pbar(title, num_items)
    if @progress
      @pbar = ProgressBar.create(:title => title, :total => num_items,
                                :format => PBAR_FORMAT, :length => 80)
    end
  end

  def inc_pbar
    @pbar.increment if @pbar
  end

  def finish_pbar
    if @pbar
      @pbar.finish
      @pbar = nil
    end
  end

  def log(msg)
    return if not @verbose

    if @pbar
      @pbar.log(msg)
    else
      puts msg
    end
  end

end
