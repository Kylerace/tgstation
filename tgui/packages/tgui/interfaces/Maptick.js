import { toFixed } from 'common/math';
import { useBackend, useLocalState } from '../backend';
import { Button, Flex, LabeledControls, NoticeBox, RoundGauge, Section, LabeledList, Table, Tabs, Box, Dropdown, Input} from '../components';
import { Window } from '../layouts';

export const Maptick = (props, context) => {
  const { act, data } = useBackend(context);
  const [
    TabIndex,
    setTabIndex,
  ] = useLocalState(context, 'tab-index', 2);
  const test_name = data.test_name;
  const currently_testing = data.ongoing_test;
  return (
    <Window
    title="Maptick Testing Panel"
    width={500}
    height={485}>
      <Window.Content>
        <Flex direction="row">
          <Flex.Item mx={1}>
            {test_name != "Maptick-Test" ? test_name : "Default Test Name"}
          </Flex.Item>
          <Flex.Item mx={1}>
            <NoticeBox color={currently_testing ? 'green' : 'red'}>
              {currently_testing ? test_name+" Is Being Recorded" : "No Test Is Being Recorded"}
            </NoticeBox>
          </Flex.Item>
        </Flex>
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
            Investigation
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
            <Investigation/>
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
    standard_deviation,
  } = data;
  return (
    <Flex title="Current Maptick Stats" direction="column">
      <Flex.Item direction="column">
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
          <LabeledList.Item label="Time Elapsed in Minutes">
            {time_elapsed}
          </LabeledList.Item>
          <LabeledList.Item label="Standard Deviation">
            {standard_deviation}
          </LabeledList.Item>
        </LabeledList>
      </Flex.Item>
      <Flex.Item direction="column">
        <Button
        key={"Calculate Standard Deviation"}
        content={"Calculate Standard Deviation"}
        onClick={() => act('calculate sd')}/>
      </Flex.Item>

    </Flex>


  )
};



const Initiation = (props, context) => {
  const { act, data } = useBackend(context);
  const templates = data.templates || [];
  const selected_template = data.selected_template;
  const test_name = data.test_name;
  const currently_testing = data.ongoing_test;
  const test_intensities = ["One measurement per second","Two measurements per second","Ten measurements per second"];

  return (
  <Flex title="Start Maptick Tests" direction="column">
    <Flex direction="row" my={1}>
      <Flex.Item my={1} grow={1}>
        <Dropdown
        width="360px"
        options={templates}
        selected={selected_template || "No Template Selected"}
        onSelected={value => act('template select', {select: value})}
        />
      </Flex.Item>
    </Flex>
      <Flex direction="row" my={1}>
        <Flex.Item>
          <Input
            maxLength={50}
            width="200px"
            value={test_name}
            placeholder={test_name}
            onChange={(e, value) => act('name test', {new_name: value})}
            />
        </Flex.Item>
      </Flex>
      <Flex my={1} grow={1} direction="row">
        <Flex.Item>
          <Button //try to get this area BELOW the area with the dropdown, preferably to the side too
          key={"Load Test Template"}
          content={"Load Test Template"}
          onClick={() => act('load template')}/>
          <Button
          key={"Start Maptick Test"}
          content={"Start Maptick Test"}
          color={currently_testing ? 'red' : 'green'}
          onClick={() => act('start test')}/>
          <Button
          key={"End Maptick Test"}
          content={"End Maptick Test"}
          onClick={() => act('end test')}/>
        </Flex.Item>
      </Flex>
      <Flex my={1} grow={1} direction="row">
        <Flex.Item>
          <Button
            key={"Start Automoving"}
            content={"Start Automoving"}
            onClick={() => act('start automove')}
          />
          <Button
            key={"End Automoving"}
            content={"End Automoving"}
            onClick={() => act('end automove')}
          />
        </Flex.Item>
      </Flex>
      <Flex my={1} grow={1} direction="row">
        <Dropdown
        width="240px"
        options={test_intensities}
        onSelected={value => act('test intensity', {intensity: value})}
        />
      </Flex>
  </Flex>
 )
};

const Investigation = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Flex title="Investigation" direction="column">
      <Flex.Item>
        <Button
        key={"Include Total Player Movement"}
        content={"Include Total Player Movement"}
        onClick={() => act('include player movement')}/>
      </Flex.Item>
    </Flex>
  )
};
