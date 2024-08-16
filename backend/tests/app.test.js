const supertest = require("supertest");
const { expect } = require("@jest/globals");
const app = require("../app");
const db = require("../db");
const Movie = require("../models/movie");

const request = supertest(app);
const endpoint = "/api/movies";

describe(endpoint, () => {
  beforeAll(async () => {
    await db.connect();
  });

  afterAll(async () => {
    await db.close();
  });

  afterEach(async () => {
    await Movie.deleteMany({});
  });


  describe("POST /", () => {
    it("should return 400 if request is not valid", async () => {
      const res = await request.post(endpoint).send({});

      expect(res.status).toBe(400);
    });

    it("should store the movie and return 201 if request is valid", async () => {
      const movie = { title: "m" };

      const res = await request.post(endpoint).send(movie);

      expect(res.status).toBe(201);
      expect(res.body.title).toBe(movie.title);
      expect(res.body._id).toBeTruthy();

      const movieInDb = await Movie.findById(res.body._id);
      expect(movieInDb).toBeTruthy();
      expect(movieInDb.title).toBe(movie.title);
    });
  });

  describe("DELETE /:id", () => {
    it("should return 404 if movie was not found", async () => {
      const nonExistentId = "5f5f5f5f5f5f5f5f5f5f5f5f";
      const res = await request.delete(`${endpoint}/${nonExistentId}`);

      expect(res.status).toBe(404);
    });

    it("should delete the movie and return 204", async () => {
      const movie = new Movie({ title: "m" });
      await movie.save();

      const res = await request.delete(`${endpoint}/${movie._id}`);

      expect(res.status).toBe(204);
      const movieInDb = await Movie.findById(movie._id);
      expect(movieInDb).toBeFalsy();
    });
  });
});