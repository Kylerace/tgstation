import { useBackend } from "../../backend";
import { Stack } from "../../components";


export function MCMetadata(props) {
  const { act } = useBackend();
  const { meta } = props;
  const {
    ident,
    starting_tick_usage,
    ending_tick_usage,
    goto_sleep_reason,
    tick_limit,
    skip_ticks,
    sleep_delta,
    run_level,
    subsystems,
    post_mc_usage,
    maptick,
    post_maptick_usage,
  } = meta;
  return (
    <Stack>
      <Stack.Item>
        start: {starting_tick_usage} end: {ending_tick_usage} \
        ({ending_tick_usage - starting_tick_usage})
      </Stack.Item>
      <Stack.Item>
        tick limit: {tick_limit}
      </Stack.Item>
      <Stack.Item>
        post_mc_usage: {post_mc_usage}
        maptick: {maptick}
        post_maptick_usage: {post_maptick_usage}
      </Stack.Item>
    </Stack>
  );
}
