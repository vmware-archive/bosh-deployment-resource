#!/bin/bash

PWD=$(dirname $0)

cd ${PWD:?}

zip -r ../tile.pivotal *
