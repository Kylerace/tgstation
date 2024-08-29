#define MC_TICK_CHECK ( ( TICK_USAGE > Master.current_ticklimit || src.state != SS_RUNNING ) ? pause() : 0 )

#define MC_SPLIT_TICK_INIT(phase_count) var/original_tick_limit = Master.current_ticklimit; var/split_tick_phases = ##phase_count
#define MC_SPLIT_TICK \
	if(split_tick_phases > 1){\
		Master.current_ticklimit = ((original_tick_limit - TICK_USAGE) / split_tick_phases) + TICK_USAGE;\
		--split_tick_phases;\
	} else {\
		Master.current_ticklimit = original_tick_limit;\
	}

// Used to smooth out costs to try and avoid oscillation.
#define MC_AVERAGE_FAST(average, current) (0.7 * (average) + 0.3 * (current))
#define MC_AVERAGE(average, current) (0.8 * (average) + 0.2 * (current))
#define MC_AVERAGE_SLOW(average, current) (0.9 * (average) + 0.1 * (current))

#define MC_AVG_FAST_UP_SLOW_DOWN(average, current) (average > current ? MC_AVERAGE_SLOW(average, current) : MC_AVERAGE_FAST(average, current))
#define MC_AVG_SLOW_UP_FAST_DOWN(average, current) (average < current ? MC_AVERAGE_SLOW(average, current) : MC_AVERAGE_FAST(average, current))

///creates a running average of "things elapsed" per time period when you need to count via a smaller time period.
///eg you want an average number of things happening per second but you measure the event every tick (50 milliseconds).
///make sure both time intervals are in the same units. doesnt work if current_duration > total_duration or if total_duration == 0
#define MC_AVG_OVER_TIME(average, current, total_duration, current_duration) ((((total_duration) - (current_duration)) / (total_duration)) * (average) + (current))

#define MC_AVG_MINUTES(average, current, current_duration) (MC_AVG_OVER_TIME(average, current, 1 MINUTES, current_duration))

#define MC_AVG_SECONDS(average, current, current_duration) (MC_AVG_OVER_TIME(average, current, 1 SECONDS, current_duration))

#define NEW_SS_GLOBAL(varname) if(varname != src){if(istype(varname)){Recover();qdel(varname);}varname = src;}

#define START_PROCESSING(Processor, Datum) if (!(Datum.datum_flags & DF_ISPROCESSING)) {Datum.datum_flags |= DF_ISPROCESSING;Processor.processing += Datum}
#define STOP_PROCESSING(Processor, Datum) Datum.datum_flags &= ~DF_ISPROCESSING;Processor.processing -= Datum;Processor.currentrun -= Datum

/// Returns true if the MC is initialized and running.
/// Optional argument init_stage controls what stage the mc must have initializted to count as initialized. Defaults to INITSTAGE_MAX if not specified.
#define MC_RUNNING(INIT_STAGE...) (Master && Master.processing > 0 && Master.current_runlevel && Master.init_stage_completed == (max(min(INITSTAGE_MAX, ##INIT_STAGE), 1)))

#define MC_LOOP_RTN_NEWSTAGES 1
#define MC_LOOP_RTN_GRACEFUL_EXIT 2

//! SubSystem flags (Please design any new flags so that the default is off, to make adding flags to subsystems easier)

/// subsystem does not initialize.
#define SS_NO_INIT (1 << 0)

/** subsystem does not fire. */
/// (like can_fire = 0, but keeps it from getting added to the processing subsystems list)
/// (Requires a MC restart to change)
#define SS_NO_FIRE (1 << 1)

/** Subsystem only runs on spare cpu (after all non-background subsystems have ran that tick) */
/// SS_BACKGROUND has its own priority bracket, this overrides SS_TICKER's priority bump
#define SS_BACKGROUND (1 << 2)

/** Treat wait as a tick count, not DS, run every wait ticks. */
/// (also forces it to run first in the tick (unless SS_BACKGROUND))
/// (We don't want to be choked out by other subsystems queuing into us)
/// (implies all runlevels because of how it works)
/// This is designed for basically anything that works as a mini-mc (like SStimer)
#define SS_TICKER (1 << 3)

/** keep the subsystem's timing on point by firing early if it fired late last fire because of lag */
/// ie: if a 20ds subsystem fires say 5 ds late due to lag or what not, its next fire would be in 15ds, not 20ds.
#define SS_KEEP_TIMING (1 << 4)

/** Calculate its next fire after its fired. */
/// (IE: if a 5ds wait SS takes 2ds to run, its next fire should be 5ds away, not 3ds like it normally would be)
/// This flag overrides SS_KEEP_TIMING
#define SS_POST_FIRE_TIMING (1 << 5)

/// If this subsystem doesn't initialize, it should not report as a hard error in CI.
/// This should be used for subsystems that are flaky for complicated reasons, such as
/// the Lua subsystem, which relies on auxtools, which is unstable.
/// It should not be used simply to silence CI.
#define SS_OK_TO_FAIL_INIT (1 << 6)

//! SUBSYSTEM STATES
#define SS_IDLE 0 /// ain't doing shit.
#define SS_QUEUED 1 /// queued to run
#define SS_RUNNING 2 /// actively running
#define SS_PAUSED 3 /// paused by mc_tick_check
#define SS_SLEEPING 4 /// fire() slept.
#define SS_PAUSING 5 /// in the middle of pausing

// Subsystem init stages
#define INITSTAGE_EARLY 1 //! Early init stuff that doesn't need to wait for mapload
#define INITSTAGE_MAIN 2 //! Main init stage
#define INITSTAGE_MAX 2 //! Highest initstage.

#define SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/controller/subsystem/##X);\
/datum/controller/subsystem/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
	PreInit();\
}\
/datum/controller/subsystem/##X

#define TIMER_SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/controller/subsystem/timer/##X);\
/datum/controller/subsystem/timer/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
	PreInit();\
}\
/datum/controller/subsystem/timer/##X/fire() {..() /*just so it shows up on the profiler*/} \
/datum/controller/subsystem/timer/##X

#define MOVEMENT_SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/controller/subsystem/movement/##X);\
/datum/controller/subsystem/movement/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
	PreInit();\
}\
/datum/controller/subsystem/movement/##X/fire() {..() /*just so it shows up on the profiler*/} \
/datum/controller/subsystem/movement/##X

#define PROCESSING_SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/controller/subsystem/processing/##X);\
/datum/controller/subsystem/processing/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
	PreInit();\
}\
/datum/controller/subsystem/processing/##X/fire() {..() /*just so it shows up on the profiler*/} \
/datum/controller/subsystem/processing/##X

#define FLUID_SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/controller/subsystem/fluids/##X);\
/datum/controller/subsystem/fluids/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
	PreInit();\
}\
/datum/controller/subsystem/fluids/##X/fire() {..() /*just so it shows up on the profiler*/} \
/datum/controller/subsystem/fluids/##X

#define VERB_MANAGER_SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/controller/subsystem/verb_manager/##X);\
/datum/controller/subsystem/verb_manager/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
	PreInit();\
}\
/datum/controller/subsystem/verb_manager/##X/fire() {..() /*just so it shows up on the profiler*/} \
/datum/controller/subsystem/verb_manager/##X

#define MC_SLEEPING_PROCS_TICKS_TO_KEEP 100

#define SLEEPING_PROC_FILE 1
#define SLEEPING_PROC_PROC 2
#define SLEEPING_PROC_LINE 3
#define SLEEPING_PROC_SLEEP_WORLDTIME 4
#define SLEEPING_PROC_SLEEP_DURATION 5
#define SLEEPING_PROC_TICK_USAGE_BEFORE_SLEEP 6
#define SLEEPING_PROC_WAKEUP_WORLDTIME 7
#define SLEEPING_PROC_WAKE_DURATION 8
#define SLEEPING_PROC_WAKEUP_TICK_USAGE 9
#define SLEEPING_PROC_METADATA 10

/// always the first element of a metadata list
#define METADATA_IDENTIFIER "ident"

//TODOKYLER: figure out mc error logic


///marks this metadata as following the MC metadata format
#define METADATA_IDENTIFIER_MC "MC_METADATA"
#define MC_METADATA_STARTING_TICK_USAGE "starting_tick_usage"
#define MC_METADATA_ENDING_TICK_USAGE "ending_tick_usage"
#define MC_METADATA_GOTO_SLEEP_REASON "goto_sleep_reason"
	#define MC_METADATA_GOTO_SLEEP_REASON_UNSET -1
	#define MC_METADATA_GOTO_SLEEP_REASON_FINISHED 0 //TODOKYLER: fill this out
	///MC stopped without running because starting tick usage was greater than
	///the mc's tick limit - other sleeping procs took up most of the tick
	#define MC_METADATA_GOTO_SLEEP_REASON_TICK_CONTENTION 1
	#define MC_METADATA_GOTO_SLEEP_REASON_CHECKQUEUE_ERROR 2
	#define MC_METADATA_GOTO_SLEEP_REASON_RUNQUEUE_ERROR 3
/// the ticklimit when RunQueue() is called if possible.
/// if it never gets to RunQueue() this is given the value at the very start of Loop()
#define MC_METADATA_TICK_LIMIT "tick_limit"
#define MC_METADATA_SKIP_TICKS "skip_ticks"
#define MC_METADATA_SLEEP_DELTA "sleep_delta"
#define MC_METADATA_RUNLEVEL "runlevel"
#define MC_METADATA_SUBSYSTEMS "subsystems"
#define MC_METADATA_POST_MC_USAGE "post_mc_usage"
#define MC_METADATA_MAPTICK "maptick"
#define MC_METADATA_POST_MAPTICK_USAGE "post_maptick"

///for fields with units of tick usage that are set later than list creation
#define MC_METADATA_USAGE_UNSET -1

#define MC_METADATA_CREATE_LIST(starting_tick_usage, tick_limit, skip_ticks, sleep_delta, runlevel)\
	list(\
		METADATA_IDENTIFIER = METADATA_IDENTIFIER_MC,\
		MC_METADATA_STARTING_TICK_USAGE = starting_tick_usage,\
		MC_METADATA_ENDING_TICK_USAGE = MC_METADATA_USAGE_UNSET,\
		MC_METADATA_GOTO_SLEEP_REASON = MC_METADATA_GOTO_SLEEP_REASON_UNSET,\
		MC_METADATA_TICK_LIMIT = tick_limit,\
		MC_METADATA_SKIP_TICKS = skip_ticks,\
		MC_METADATA_SLEEP_DELTA = sleep_delta,\
		MC_METADATA_RUNLEVEL = runlevel,\
		MC_METADATA_SUBSYSTEMS = list(),\
		MC_METADATA_POST_MC_USAGE = MC_METADATA_USAGE_UNSET,\
		MC_METADATA_MAPTICK = MC_METADATA_USAGE_UNSET,\
		MC_METADATA_POST_MAPTICK_USAGE = MC_METADATA_USAGE_UNSET,\
	)

#define MC_METADATA_SUBSYSTEM_NAME "name"
#define MC_METADATA_SUBSYSTEM_TICK_USAGE "tick_usage"
#define MC_METADATA_SUBSYSTEM_SCHEDULED_LIMIT "scheduled_limit"
#define MC_METADATA_SUBSYSTEM_OVERTIME "overtime"
#define MC_METADATA_SUBSYSTEM_PRIORITY "priority"
#define MC_METADATA_SUBSYSTEM_FLAGS "flags"
#define MC_METADATA_SUBSYSTEM_START_STATE "start_state"
#define MC_METADATA_SUBSYSTEM_END_STATE "end_state"

#define MC_METADATA_CREATE_SUBSYSTEM_LIST(name, scheduled_limit, priority, flags, start_state)\
	list(\
		MC_METADATA_SUBSYSTEM_NAME = name,\
		MC_METADATA_SUBSYSTEM_TICK_USAGE = 0,\
		MC_METADATA_SUBSYSTEM_SCHEDULED_LIMIT = scheduled_limit,\
		MC_METADATA_SUBSYSTEM_OVERTIME = 0,\
		MC_METADATA_SUBSYSTEM_PRIORITY = priority,\
		MC_METADATA_SUBSYSTEM_FLAGS = flags,\
		MC_METADATA_SUBSYSTEM_START_STATE = start_state,\
		MC_METADATA_SUBSYSTEM_END_STATE = NONE\
	)

#define _sleep(x) sleep_metadata(x, null)

#define sleep_metadata(x, meta) \
	do {\
		var/list/_us = list("[__FILE__]","[__PROC__]","[__LINE__]", world.time, x, TICK_USAGE, 0, 0, 0, meta);\
		Master.active_sleeps++;\
		/*Master.last_resumer = _us;*/\
		sleep(x);\
		_us[SLEEPING_PROC_WAKEUP_TICK_USAGE] = TICK_USAGE;\
		if(Master.last_resumer) {\
			Master.last_resumer[SLEEPING_PROC_WAKE_DURATION] = TICK_USAGE - Master.last_resumer[SLEEPING_PROC_WAKEUP_TICK_USAGE];\
		}\
		_us[SLEEPING_PROC_WAKEUP_WORLDTIME] = world.time;\
		Master.last_resumer = _us;\
		Master.resuming_procs["[world.time]"] += list(_us);\
		Master.active_sleeps--;\
	} while(FALSE);

/// Added to the ends of hot client procs/verbs that execute after maptick so master can estimate their cost
#define POST_MAPTICK_MAX_TICK_USAGE Master.last_post_maptick_tick_usage = TICK_USAGE;

