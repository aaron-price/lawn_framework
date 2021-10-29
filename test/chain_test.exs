defmodule ChainTest do
  use ExUnit.Case
  alias Lawn.Chain
  alias Lawn.Chains
  alias Lawn.Interceptors, as: I

  @moduledoc """
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


  setup do
    args = %{user: 1, dog: 1}
    l = Lawn.new(Lawn.Db.db())
    |> Map.put(:current, args)
    %{lawn: l, args: args}
  end

  test "General interceptor processing", %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    assert pre_lawn.db.dog[did].energy == 100
    l1 = Chain.process_chain(pre_lawn, Chains.train_speed(), args)
    assert       l1.db.dog[did].energy == 95

    l2 = Chain.process_chain(l1, Chains.train_speed(), args)
    assert       l2.db.dog[did].energy == 90

    l3 = Chain.process_chain(l2, Chains.rest(), args)
    assert       l3.db.dog[did].energy == 100

  end


  test "{:cont, :reset, lawn}", %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.cont_reset_lawn/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0
    assert pre_lawn.db.dog[did].energy == 100

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].energy == 100
    assert l.db.dog[did].speed == 1
    assert l.db.dog[did].hunger == 1
  end
  test "{:cont, :keep, lawn}", %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.cont_keep_lawn/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].energy == 95
    assert l.db.dog[did].speed == 2
    assert l.db.dog[did].hunger == 1
  end
  test "{:halt, :reset, lawn}", %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.halt_reset_lawn/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].energy == 100
    assert l.db.dog[did].speed == 1
    assert l.db.dog[did].hunger == 0
  end
  test "{:halt, :keep, lawn}", %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.halt_keep_lawn/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].energy == 95
    assert l.db.dog[did].speed == 2
    assert l.db.dog[did].hunger == 0
  end

  test "{:cont, :keep, chain}", %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.cont_keep_chain/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0
    assert pre_lawn.db.dog[did].happiness == 100

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].speed == 2
    assert l.db.dog[did].hunger == 1
    assert l.db.dog[did].happiness == 99
  end
  test "{:cont, :reset, chain}",  %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.cont_reset_chain/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0
    assert pre_lawn.db.dog[did].happiness == 100

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].speed == 1
    assert l.db.dog[did].hunger == 1
    assert l.db.dog[did].happiness == 99
  end
  test "{:halt, :keep, chain}",  %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.halt_keep_chain/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0
    assert pre_lawn.db.dog[did].happiness == 100

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].speed == 2
    assert l.db.dog[did].hunger == 0
    assert l.db.dog[did].happiness == 99
  end
  test "{:halt, :reset, chain}", %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.halt_reset_chain/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0
    assert pre_lawn.db.dog[did].happiness == 100

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].speed == 1
    assert l.db.dog[did].hunger == 0
    assert l.db.dog[did].happiness == 99
  end

  test "{:cont, :keep, list_of_interceptor}",  %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.cont_keep_li/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0
    assert pre_lawn.db.dog[did].happiness == 100

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].speed == 2
    assert l.db.dog[did].hunger == 1
    assert l.db.dog[did].happiness == 99
  end
  test "{:cont, :reset, list_of_interceptor}", %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.cont_reset_li/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0
    assert pre_lawn.db.dog[did].happiness == 100

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].speed == 1
    assert l.db.dog[did].hunger == 1
    assert l.db.dog[did].happiness == 99
  end
  test "{:halt, :reset, list_of_interceptor}", %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.halt_reset_li/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0
    assert pre_lawn.db.dog[did].happiness == 100

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].speed == 1
    assert l.db.dog[did].hunger == 0
    assert l.db.dog[did].happiness == 99
  end
  test "{:halt, :keep, list_of_interceptor}",  %{lawn: pre_lawn, args: %{user: _uid, dog: did} = args} do
    intcs = %Lawn.Chain{interceptors: [&I.inc_speed/2, &I.halt_keep_li/2, &I.get_hungry/2]}
    assert pre_lawn.db.dog[did].speed == 1
    assert pre_lawn.db.dog[did].hunger == 0
    assert pre_lawn.db.dog[did].happiness == 100

    l = Chain.process_chain(pre_lawn, intcs, args)
    assert l.db.dog[did].speed == 2
    assert l.db.dog[did].hunger == 0
    assert l.db.dog[did].happiness == 99
  end

end
