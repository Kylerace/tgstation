import { BooleanLike } from 'common/react';

export type SubsystemData = {
  can_fire: BooleanLike;
  cost_ms: number;
  doesnt_fire: BooleanLike;
  init_order: number;
  initialization_failure_message: string | undefined;
  initialized: BooleanLike;
  last_fire: number;
  name: string;
  next_fire: number;
  ref: string;
  tick_overrun: number;
  tick_usage: number;
};

export type ControllerData = {
  world_time: number;
  fast_update: BooleanLike;
  active_sleeps: number;
  pre_mc_usage: number;
  mc_usage: number;
  post_mc_usage: number;
  map_cpu: number;
  post_maptick_usage: number;
  subsystems: SubsystemData[];
  ticks: Tick[];
};

/*
#define SLEEPING_PROC_FILE 1
#define SLEEPING_PROC_PROC 2
#define SLEEPING_PROC_LINE 3
#define SLEEPING_PROC_SLEEP_WORLDTIME 4
#define SLEEPING_PROC_SLEEP_DURATION 5
#define SLEEPING_PROC_TICK_USAGE_BEFORE_SLEEP 6
#define SLEEPING_PROC_WAKE_DURATION 7
*/

export type ResumingProc = {
  file: string;
  proc: string;
  line: string;
  // world.time it went to sleep
  sleep_world_time: number;
  // how long it was scheduled to sleep for
  sleep_duration: number;
  // tick usage right before it went to sleep
  tick_usage_before_sleep: number;
  // world.time when it woke up
  wakeup_worldtime: number;
  // total time spent processing this (same units as tick usage)
  wake_duration: number;
  // tick usage right when the proc woke up
  wakeup_tick_usage: number;
  metadata: any;
};

export type SubsystemMetadata = {
  name: string;
  tick_usage: number;
  scheduled_limit: number;
  overtime: number;
  priority: number;
  flags: number;
  start_state: number;
  end_state: number;
}

export type MCMetadata = {
  ident: string;
  starting_tick_usage: number;
  ending_tick_usage: number;
  goto_sleep_reason: number;
  tick_limit: number;
  skip_ticks: number;
  sleep_delta: number;
  runlevel: number;
  subsystems: SubsystemMetadata[];
  post_mc_usage: number;
  maptick: number;
  post_maptick: number;
}

/*
  TODOKYLER: route subsystem views through ticks via metadata added in the
  sleep shim in master. maybe a callback thats called when the next _sleep()
  happens?
 */
export type Tick = {
  world_time: number;
  // pre_mc: number;
  // mc: number;
  // post_mc: number;
  // maptick: number;
  // post_maptick: number;
  resuming_procs: ResumingProc[];
};

export enum SortType {
  Name,
  Cost,
  InitOrder,
  LastFire,
  NextFire,
  TickUsage,
  TickOverrun,
}
