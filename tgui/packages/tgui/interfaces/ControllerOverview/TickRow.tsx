
import { useState } from 'react';

import { useBackend } from '../../backend';
import {
  Stack,
  Table,
} from '../../components';
import { Tick } from './types';

type Props = {
  tick: Tick;
  max: number;
}

export function TickRow(props: Props) {
  const { act } = useBackend();
  const { tick, max } = props;
  const { world_time, resuming_procs } = tick;

  const [is_expanded] = useState(false);

  return (
    <Table.Row p={3}>
      <Table.Cell inline textAlign='center'>
        {world_time}:
      </Table.Cell>
      <Table.Cell textAlign='center'>
      {(resuming_procs.map((proc) => (

        <Stack.Item key={proc.proc}>
          <Stack>
            <Stack.Item>
              <Stack vertical fill>
                <Stack.Item>
                  {proc.proc} {proc.file} line {proc.line}
                </Stack.Item>
                <Stack.Item>
                  went to sleep: {proc.sleep_world_time} \
                  woke up: {proc.wakeup_worldtime} \
                  ({proc.sleep_world_time + proc.sleep_duration})
                </Stack.Item>
                <Stack.Item>
                  duration: {proc.sleep_duration}
                </Stack.Item>
                <Stack.Item>
                  wakeup tick usage: {proc.wakeup_tick_usage}%
                </Stack.Item>
                <Stack.Item>
                  wake duration: {proc.wake_duration}%
                </Stack.Item>
                <Stack.Item>

                {proc.metadata !== null && Object.prototype.hasOwnProperty.call(proc.metadata, 'ident') && proc.metadata.ident === 'MC_METADATA' && (
                  <Stack vertical fill>

                    <Stack.Item>
                      start: {proc.metadata.starting_tick_usage} end: {proc.metadata.ending_tick_usage}
                      ({proc.metadata.ending_tick_usage - proc.metadata.starting_tick_usage})
                    </Stack.Item>
                    <Stack.Item>
                      tick limit: {proc.metadata.tick_limit}
                    </Stack.Item>
                    <Stack.Item>
                      post mc: {proc.metadata.post_mc_usage}
                      maptick: {proc.metadata.maptick}
                      post maptick usage: {proc.metadata.post_maptick_usage}
                    </Stack.Item>
                    <Stack.Item>
                      {(proc.metadata.subsystems.map((subsystem) => (
                        <Stack key={subsystem.name} vertical fill>
                          <Stack.Item>
                            {subsystem.name} ({subsystem.tick_usage} / {subsystem.scheduled_limit})%
                          </Stack.Item>
                        </Stack>
                      )))}
                    </Stack.Item>
                  </Stack>
                )}
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )))}
      </Table.Cell>
    </Table.Row>
  );
}
