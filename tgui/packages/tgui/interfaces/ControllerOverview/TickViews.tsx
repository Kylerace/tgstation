

import { useState } from 'react';

import { useBackend } from '../../backend';
import { Button, Section, Stack, Table } from '../../components';
import { TickRow } from './TickRow';
import { ControllerData, Tick } from './types';

type Props = {

}

// sorts, and then adds missing ticks to the array until every multiple of
// 0.5 deciseconds between the lowest and highest world.time tick exists,
// even if empty
function sanitizeTicks(old_ticks: Tick[]) {

  // const sorted = ticks.sort((a, b) => {
  //  return a.world_time > b.world_time ? 1 : -1;
  // });
  const ticks = old_ticks.toSorted((a, b) => {
    return a.world_time - b.world_time;
  });
  const lowest = ticks[0].world_time;
  const highest = ticks[ticks.length - 1].world_time;

  let current: number = lowest;
  let i = ticks.length - 1;
  while(i > 0) {
    while(ticks[i-1].world_time < ticks[i].world_time - 0.5) {
      ticks.splice(i, 0,
        { world_time: ticks[i-1].world_time + 0.5, resuming_procs: [] }
      );
      i++;
    }
    i--;
  }
  return ticks;
}

// returns a new array consisting of every unique tick in both input arrays
// assumes that if both lists contain a tick with matching world.time, the
// resuming procs in both lists will be identical
// also assumes old_ticks is sorted
function combineTicks(new_ticks: Tick[], old_ticks: Tick[]) {
  const ticks = [...old_ticks];

  const lowest = ticks[0].world_time;
  const highest = ticks[ticks.length - 1].world_time;

  for(let i = 0; i < new_ticks.length; i++) {
    let curr_new = new_ticks[i].world_time;
    if(curr_new < lowest || curr_new > highest) {
      ticks.push(new_ticks[i]); // TODOKYLER: hope this is a copy
    }
  }
  return sanitizeTicks(ticks);
}

export function TickViews(props) {
  const { data } = useBackend<ControllerData>();
  const raw_ticks = data.ticks;

  const [ticks, updateTicks] = useState(sanitizeTicks(raw_ticks));

  // const sorted = ticks.sort((a, b) => {
  //  return a.world_time > b.world_time ? 1 : -1;
  // });


  const lowest = ticks[0].world_time;
  const highest = ticks[ticks.length - 1].world_time;

  return (
    <Section fill scrollable title="Ticks">
      <Stack>
        <Stack.Item>
          <Button
            selected={false}
            onClick={() => updateTicks(combineTicks(data.ticks, ticks))}>
            Update
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Table>
            {ticks.slice(0, 50).map((tick) => (
              <TickRow key={tick.world_time} tick={tick} max={highest} />
            ))}
          </Table>
        </Stack.Item>
      </Stack>

    </Section>
  );
}
