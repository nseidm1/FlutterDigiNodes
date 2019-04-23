import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/logic/home_logic.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final _logic = HomeLogic();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _logic.loadingDNS,
      builder: (BuildContext context, bool loading, Widget child) {
        return Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset('assets/logo.png'),
            ),
            title: _CoinDefinitionDropdown(
              coinDefinition: _logic.coinDefinition,
              enabled: !loading,
            ),
            actions: <Widget>[
              loading
                  ? Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : IconButton(
                      onPressed: _logic.onShareButtonPressed,
                      icon: Icon(Icons.share),
                    ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 12.0),
                child: Row(
                  children: <Widget>[
                    Expanded(child: TextField()),
                    FlatButton(
                      onPressed: _logic.onAddManualNodePressed,
                      child: Text('ADD'),
                    ),
                  ],
                ),
              ),
              _HomeListHeader(
                text: 'Messages (123)',
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 50,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text('Item #$index'),
                    );
                  },
                ),
              ),
              Container(
                child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _logic.nodes,
                      _logic.openScanner.openCount,
                      _logic.openScanner.one,
                      _logic.openScanner.two,
                      _logic.openScanner.three,
                      _logic.openScanner.four,
                      _logic.openScanner.five,
                      _logic.openScanner.six
                    ]),
                    builder: (BuildContext context, Widget child) {
                      return _HomeListHeader(
                        text: 'Nodes (${_logic.nodesCount}) '
                            'Open(${_logic.openScanner.openCount.value}) '
                            'Recent (0)\nCrawling (0)\n'
                            'Open Checkers\n${_logic.openScanner.one.value} - ${_logic.openScanner.two.value} - ${_logic.openScanner.three.value} - ${_logic.openScanner.four.value} - ${_logic.openScanner.five.value} - ${_logic.openScanner.six.value}',
                      );
                    }
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _logic.nodes,
                  builder: (BuildContext context, Widget child) {
                    return ListView.builder(
                      itemCount: _logic.nodes.length,
                      itemBuilder: (BuildContext context, int index) {
                        final node = _logic.nodes[index];
                        return ListTile(
                          title: Text('${node.address}:${node.port}'),
                          subtitle: Text('${node.open}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoinDefinitionDropdown extends StatelessWidget {
  const _CoinDefinitionDropdown({
    Key key,
    @required this.coinDefinition,
    this.enabled,
  }) : super(key: key);

  final ValueNotifier<Definition> coinDefinition;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        brightness: Brightness.dark,
        textTheme: theme.primaryTextTheme,
        iconTheme: theme.primaryIconTheme,
        canvasColor: theme.primaryColorDark,
      ),
      child: DropdownButtonHideUnderline(
        child: ValueListenableBuilder(
          valueListenable: coinDefinition,
          builder: (BuildContext context, Definition value, Widget child) {
            return DropdownButton<Definition>(
              style: theme.primaryTextTheme.subhead,
              onChanged: enabled ? (value) => coinDefinition.value = value : null,
              value: value,
              items: coinDefinitions.map<DropdownMenuItem<Definition>>((definition) {
                return DropdownMenuItem<Definition>(
                  value: definition,
                  child: Text(definition.coinName),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _HomeListHeader extends StatelessWidget {
  const _HomeListHeader({
    Key key,
    @required this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      color: Colors.grey.shade400,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.subhead.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}
