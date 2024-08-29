import { useBackend } from '../../backend';
import { Button, LabeledList, Section, Stack } from '../../components';
import { ControllerData } from './types';

export function OverviewSection(props) {
  const { act, data } = useBackend<ControllerData>();
  const { active_sleeps, pre_mc_usage, mc_usage, post_mc_usage, post_maptick_usage, ticks = [], fast_update, map_cpu, subsystems = [], world_time } = data;

  let overallUsage = 0;
  let overallOverrun = 0;
  for (let i = 0; i < subsystems.length; i++) {
    overallUsage += subsystems[i].tick_usage;
    overallOverrun += subsystems[i].tick_overrun;
  }

  return (
    <Section
      fill
      title="Master Overview"
      buttons={
        <Button
          tooltip="Fast Update"
          icon={fast_update ? 'check-square-o' : 'square-o'}
          color={fast_update && 'average'}
          onClick={() => {
            act('toggle_fast_update');
          }}
        >
          Fast
        </Button>
      }
    >
      <Stack fill>
        <Stack.Item grow>
          <Stack.Item grow>
            <LabeledList>
              <LabeledList.Item label="World Time">
                {world_time.toFixed(1)}
              </LabeledList.Item>
              <LabeledList.Item label="Active Sleeps">
                {active_sleeps}
              </LabeledList.Item>
            </LabeledList>
          </Stack.Item>
          <Stack.Item grow>
            <LabeledList>
              <LabeledList.Item label="Subsystem Usage">
                {(overallUsage * 0.01).toFixed(2)}%
              </LabeledList.Item>
              <LabeledList.Item label="Subsystem Overrun">
                {(overallOverrun * 0.01).toFixed(2)}%
              </LabeledList.Item>
            </LabeledList>
          </Stack.Item>
        </Stack.Item>
        <Stack.Item grow>
          <Stack>
            <Stack.Item grow>
              Pre MC: {(pre_mc_usage * 0.01).toFixed(2)}%
            </Stack.Item>
            <Stack.Item grow>
              MC: {(mc_usage * 0.01).toFixed(2)}%
            </Stack.Item>
            <Stack.Item grow>
              Post MC: {(post_mc_usage * 0.01).toFixed(2)}%
            </Stack.Item>
            <Stack.Item grow>
              Maptick: {(map_cpu * 0.01).toFixed(2)}%
            </Stack.Item>
            <Stack.Item grow>
              Post Maptick: {(post_maptick_usage * 0.01).toFixed(2)}%
            </Stack.Item>
            <Stack.Item grow>
              Total: {((pre_mc_usage + mc_usage + map_cpu + post_maptick_usage) * 0.01).toFixed(2)}%
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
}
