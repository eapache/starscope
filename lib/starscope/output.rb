require 'ruby-progressbar'

module Starscope
  class Output
    PBAR_FORMAT = '%t: %c/%C %E ||%b>%i||'.freeze

    def initialize(level, out = $stdout)
      @out = out
      @level = level
      @pbar = nil
    end

    def new_pbar(title, num_items)
      return if @level == :quiet

      @pbar = ProgressBar.create(title: title, total: num_items,
                                 format: PBAR_FORMAT, length: 80,
                                 out: @out)
    end

    def inc_pbar
      @pbar&.increment
    end

    def finish_pbar
      @pbar&.finish
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
end
