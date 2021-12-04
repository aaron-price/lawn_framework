defmodule Lawn.Chain do

  @moduledoc """
  If a %Lawn{} is a unit of past data, future data, and list of operations to get there...
  then a %Lawn.Chain{} is a list of functions to apply changes to a lawn.

  An interceptor is simply a function/2, that takes a %Lawn{}, and a %Chain{}
  Usually it returns a new lawn with some changes
  But an interceptor can also return {:pivot, chain} to short circuit the list of interceptors and apply a DIFFERENT chain.
  Or it can return {:hijack, chain} which is similar to {:pivot, chain}
  The difference is that :hijack starts with a brand new lawn, and :pivot continues using the existing one.
  Finally there is :sideload, which applies the current lawn to a new chain, but CONTINUES the current chain.

  The main entry point is Chain.process_chain


  The three variables: are you giving one intercerptor, many, or a chain? Can simply pattern match on this.

  ## What happens to the rest of the interceptors in the current chain? The verb
  :cont - They are processed
  :halt - They are not processed

  ## What lawn is used.
  :reset - drops the current lawn, spawning a new one via chain.pre_fn
  :keep  - passes in the current lawn

  ## What processing happens next
  %Lawn{}, fn, [fn], %Chain{}, :return

  Either return a tuple {lawn, intercept, process}
  Or return simply a lawn and get the default {:keep, :cont, %Lawn{}}

  """
  defstruct [
    name: "",
    interceptors: [], # list of functions that take a lawn and chain, then return a new lawn.

    # The initial data
    pre_fn: &__MODULE__.return_lawn/1, # function that takes a map of args, and returns a lawn

    args: %{}, # Gets merged into lawn.current, and passed into each interceptor
    ok_message: "",
    error_message: "",
  ]

  def return_lawn(_args), do: %Lawn{}


  def get_pre_lawn(chain, args), do: chain.pre_fn.(args)


  def get_chain_inp(:reset, _acc, chain, args), do: [chain, args]
  def get_chain_inp(:keep, acc, chain, args), do:   [acc, chain, args]

  def get_new_int_inp(:reset, _acc, chain), do: [%Lawn{}, chain]
  def get_new_int_inp(:keep, acc, chain), do:   [acc,     chain]

  def reset_with_errors(pre_lawn, new_lawn) do
    pre_lawn
    |> Map.put(:status, new_lawn.status)
    |> Map.put(:message, new_lawn.message)
  end

  def process_all_interceptors(pre_lawn, chain, args) do
    Enum.reduce_while(chain.interceptors, pre_lawn, fn (interceptor, acc) ->
      intercept = interceptor.(acc, chain)
      case intercept do
        # Default
        %Lawn{} = lawn ->                          {:cont, lawn}
        # {1,    2,     3}
        # 1: do we process the remaining list of interceptors? :cont | :halt
        # 2: do we keep the current lawn, or get a new one? :keep | :reset
        # 3: The new accumulator. %Lawn{} | %Chain{} | [interceptor_fns]
        {:cont, :keep, %Lawn{} = lawn} ->          {:cont, lawn}
        {:halt, :reset, %Lawn{} = lawn} ->         {:halt, reset_with_errors(pre_lawn, lawn)}
        {:halt, :keep, %Lawn{} = lawn} ->          {:halt, lawn}
        {:cont, :reset, %Lawn{} = lawn} ->         {:cont, reset_with_errors(pre_lawn, lawn)}

        ## Process a new chain
        {:cont, :keep, %Lawn.Chain{} = new_chain} -> {:cont, process_chain(acc, new_chain, args)}
        {:cont, :reset, %Lawn.Chain{} = new_chain} -> {:cont, process_chain(pre_lawn, new_chain, args)}
        {:halt, :keep, %Lawn.Chain{} = new_chain} -> {:halt, process_chain(acc, new_chain, args)}
        {:halt, :reset, %Lawn.Chain{} = new_chain} -> {:halt, process_chain(pre_lawn, new_chain, args)}

        ## Process a new list of interceptors, using an otherwise identical chain
        {intc_opt, lawn_opt, li} when is_list(li) ->
          chain = Map.put(chain, :interceptors, li)
          lawn = if lawn_opt == :keep, do: acc, else: pre_lawn
          {intc_opt, process_chain(lawn, chain, args)}

      end
    end)
  end


  # Either provide your own lawn, or it will just call Chain.pre_fn(args)
  def process_chain(chain, args) do
    pre_lawn = get_pre_lawn(chain, args)
    process_chain(pre_lawn, chain, args)
  end
  def process_chain(pre_lawn, chain, args) do
    pre_lawn
    |> Map.put(:message, chain.ok_message)
    |> process_all_interceptors(chain, args)
  end


end
