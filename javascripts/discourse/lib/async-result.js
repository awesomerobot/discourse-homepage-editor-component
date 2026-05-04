import { tracked } from "@glimmer/tracking";

export default class AsyncResult {
  @tracked isPending = true;
  @tracked value = null;

  constructor(promise) {
    Promise.resolve(promise).then(
      (v) => {
        this.value = v;
        this.isPending = false;
      },
      () => {
        this.isPending = false;
      }
    );
  }
}
