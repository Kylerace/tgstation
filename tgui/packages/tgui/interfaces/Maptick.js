import { toFixed } from 'common/math';
import { useBackend, useLocalState } from '../backend';
import { Button, Flex, LabeledControls, NoticeBox, RoundGauge, Section, LabeledList, Table, Tabs, Box} from '../components';
import { Window } from '../layouts';

/*const TAB2NAME = [
  {
    title: 'Status',
    component: () => Status,
  },
  {
    title: 'Initiation',
    component: () => Initiation,
  },
  {
    title: 'Miscellaneous',
    component: () => Miscellaneous,
  },
];*/

export const Maptick = (props, context) => {
  const { act, data } = useBackend(context);
  const [
    TabIndex,
    setTabIndex,
  ] = useLocalState(context, 'tab-index', 2);
  //const TabComponent = TAB2NAME[TabIndex-1].component();
  return (
    <Window
    title="Maptick Testing Panel"
    width={500}
    height={485}>
      <Window.Content>
        <Flex direction="column" height="100%">
        <Tabs>
          <Tabs.Tab
            icon="list"
            lineHeight="23px"
            selected={TabIndex === 1}
            onClick={() => setTabIndex(1)}>
            Status
          </Tabs.Tab>
          <Tabs.Tab
            icon="list"
            lineHeight="23px"
            selected={TabIndex === 2}
            onClick={() => setTabIndex(2)}>
            Initiation
          </Tabs.Tab>
          <Tabs.Tab
            icon="list"
            lineHeight="23px"
            selected={TabIndex === 3}
            onClick={() => setTabIndex(3)}>
            Miscellaneous
          </Tabs.Tab>
        </Tabs>
        {TabIndex === 1 && (
          <Status />
        )}
        {TabIndex === 2 && (
          <>
            <Initiation />
          </>
        )}
        {TabIndex === 3 && (
          <>
            <Miscellaneous/>
          </>
        )}

        </Flex>
      </Window.Content>
    </Window>
  );
}

const Status = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    ongoing_test,
    current_maptick_average,
    current_maptick_exact,
    current_moving_average,
    templates,
    players,
    time_elapsed,
  } = data;
  return (
    <Flex title="Current Maptick Stats">
      <Flex.Item>
        <LabeledList>
          <LabeledList.Item label="Current Maptick Value">
            {current_maptick_exact}
          </LabeledList.Item>
          <LabeledList.Item label="Average Maptick Value">
            {current_maptick_average}
          </LabeledList.Item>
          <LabeledList.Item label="Maptick Moving Average">
            {current_moving_average}
          </LabeledList.Item>
          <LabeledList.Item label="Number of Players">
            {players}
          </LabeledList.Item>
        </LabeledList>
      </Flex.Item>
    </Flex>


  )
};

/*

<Flex.Item grow={1}>
          <Section
            fill={false}
            title={TAB2NAME[tabIndex-1].title}>
            <TabComponent />
          </Section>
        </Flex.Item>

<Section
        title = "Maptick Menu"
        buttons={(
          <>
          <Button
          color = "blue"
          content = "Status"
          selected={tabIndex === 1}
          onClick={() => setTabIndex(1)}
          />
          <Button
          color = "blue"
          content = "Initiation"
          selected={tabIndex === 2}
          onClick={() => setTabIndex(2)}
          />
          <Button
          color = "blue"
          content = "Miscellaneous"
          selected={tabIndex === 3}
          onClick={() => setTabIndex(3)}
          />
          </>
         )}>
        </Section>

<LabeledList>
          <LabeledList.Item label="Current Maptick Value">
            {current_maptick_exact}
          </LabeledList.Item>
          <LabeledList.Item label="Average Maptick Value">
            {current_maptick_average}
          </LabeledList.Item>
          <LabeledList.Item label="Maptick Moving Average">
            {current_moving_average}
          </LabeledList.Item>
          <LabeledList.Item label="Number of Players">
            {players}
          </LabeledList.Item>
        </LabeledList>
///

<Table>
          <Table.Row>
            <Table.Cell>
              content={current_maptick_average+" Current Average Maptick"}
            </Table.Cell>
            <Table.Cell>
              content={current_maptick_exact+" Current Maptick"}
            </Table.Cell>
            <Table.Cell>
              content={current_moving_average+" Current Moving Average"}
            </Table.Cell>
            <Table.Cell>
              content={players+" Number of Players"}
            </Table.Cell>
          </Table.Row>
        </Table>
*/

const Initiation = (props, context) => {
  const { act, data } = useBackend(context);
  return (

    <Flex title="Start Maptick Tests">
      <Flex.Item>

      </Flex.Item>
    </Flex>
 )
};

const Miscellaneous = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Flex title="Miscellaneous">
      <Flex.Item>

      </Flex.Item>
    </Flex>
  )
};



