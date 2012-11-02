$data_version = '2.0';
%repos = (
  'gitolite-admin' => {
    'R' => {
      'admin' => 1
    },
    'W' => {
      'admin' => 1
    },
    'admin' => [
      [
        0,
        'refs/.*',
        'RW+'
      ]
    ]
  },
  'testing' => {
    '@all' => [
      [
        1,
        'refs/.*',
        'RW+'
      ]
    ],
    'R' => {
      '@all' => 1
    },
    'W' => {
      '@all' => 1
    }
  }
);
