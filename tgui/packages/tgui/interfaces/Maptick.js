import { toFixed } from 'common/math';
import { useBackend, useLocalState } from '../backend';
import { Button, Flex, LabeledControls, NoticeBox, RoundGauge, Section, LabeledList} from '../components';
import { Window } from '../layouts';



/*export const Maptick = (props, context) => {
  const { act, data } = useBackend(context);
  /*const [
    tabIndex,
    setTabIndex,
  ] = useLocalState(context, 'tab-index', 2);
  const TabComponent = TAB2NAME[tabIndex-1].component();
  return (
    <Window
    title="Maptick Testing Panel"
    width={500}
    height={485}>
      <Window.Content scrollable>
        <Section
        title = "Maptick Menu"
        buttons={(
          <>
          <Button
          color = "blue"
          content = "Status"
          //onClick={() => setTabIndex(0)}
          />
          <Button
          color = "blue"
          content = "Initiation"
          //onClick={() => setTabIndex(1)}
          />
          <Button
          color = "blue"
          content = "Miscellaneous"
          //onClick={() => setTabIndex(2)}
          />
          </>
         )}>

        </Section>
      </Window.Content>
    </Window>
  );
}*/

/*  const Status = (props, context) => {
    const { act, data } = useBackend(context);
    const {
      ongoing_test,
      current_maptick_average,
      current_maptick_exact,
      current_moving_average,
      templates,
      players
    } = data;
  }

  const Initiation = (props, context) => {
    const { act, data } = useBackend(context);

  }

  const Miscellaneous = (props, context) => {
    const { act, data } = useBackend(context);

  }
*/

export const Maptick = (props, context) => {
  const { act, data } = useBackend(context);
  // Extract `health` and `color` variables from the `data` object.
  //const {
  //  health,
  //  color,
  //} = data;
  return (
    <Window resizable>
      <Window.Content scrollable>
        <Section title="Health status">

        </Section>
      </Window.Content>
    </Window>
  );
};
